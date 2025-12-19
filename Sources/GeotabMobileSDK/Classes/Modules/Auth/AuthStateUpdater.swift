import AppAuth
import BackgroundTasks
import Combine

protocol AuthStateUpdating {
    func start()
    func stop()
    func updateAuthStates() async
    func registerForBackgroundUpdates()
}

protocol BackgroundScheduling {
    func register(forTaskWithIdentifier identifier: String, using queue: dispatch_queue_t?, launchHandler: @escaping (BGTask) -> Void) -> Bool
    func submit(_ taskRequest: BGTaskRequest) throws
}

actor AuthStateUpdater: AuthStateUpdating {
    private static let scheduleToleranceInNanoseconds: UInt64 = 10 * 1_000_000_000
    private static let rescheduleDelayInNanoseconds: UInt64 = 10 * 1_000_000_000
    private static let defaultMaxRetryInterval: TimeInterval = 15 * 60 // 15 minutes
    private static let defaultBaseRetryInterval: TimeInterval = 2 * 60 // 2 minutes

    private let authUtil: any AuthUtil
    private let minimumScheduleInterval: TimeInterval
    private let maxRetryInterval: TimeInterval
    private let baseRetryInterval: TimeInterval

    private var updateTask: Task<Void, any Error>?
    private var nextScheduledUpdateInNanoseconds: UInt64?
    private var lastUpdateCompletedAt: UInt64?
    private var registeredForBackgroundRefresh = false
    private var retryAttempts: [String: Int] = [:]

    nonisolated(unsafe) private var newAuthStateListener: AnyCancellable?
    nonisolated(unsafe) private var backgroundStateListener: AnyCancellable?
    nonisolated(unsafe) private let backgroundScheduler: any BackgroundScheduling

    init(authUtil: any AuthUtil = DefaultAuthUtil(),
         backgroundScheduler: any BackgroundScheduling = BGTaskScheduler.shared,
         minimumScheduleInterval: TimeInterval = 120,
         baseRetryInterval: TimeInterval = defaultBaseRetryInterval,
         maxRetryInterval: TimeInterval = defaultMaxRetryInterval) {
        self.authUtil = authUtil
        self.backgroundScheduler = backgroundScheduler
        self.minimumScheduleInterval = minimumScheduleInterval
        self.baseRetryInterval = baseRetryInterval
        self.maxRetryInterval = maxRetryInterval
    }

    nonisolated func start() {
        initializeUpdates()
        initializeBackgroundUpdates()
    }
    
    nonisolated func stop() {
        newAuthStateListener?.cancel()
        backgroundStateListener?.cancel()
        Task { [weak self] in await self?.clearScheduledUpdate() }
    }
    
    nonisolated func nextUpdateInNanoseconds(for expiration: TimeInterval) -> UInt64 {
        // 1/2 of the expiration time, with a minimum of 2 mins
        let expirationTimeInterval = expiration / 2
        return UInt64(max(expirationTimeInterval, minimumScheduleInterval)) * 1_000_000_000
    }
    
    nonisolated private func initializeUpdates() {
        newAuthStateListener = NotificationCenter.default
            .publisher(for: .newAuthState)
            .compactMap { notification in
                notification.userInfo?[DefaultAuthUtil.authStateKey] as? OIDAuthState
            }
            .sink { [weak self] authState in
                Task { await self?.scheduleUpdate(for: authState) }
            }
    }
    
    func clearScheduledUpdate() {
        updateTask?.cancel()
        updateTask = nil
        nextScheduledUpdateInNanoseconds = nil
    }
    
    func scheduleUpdate(for authState:OIDAuthState) async {
        guard let accessTokenExpirationDate = authState.lastTokenResponse?.accessTokenExpirationDate else { return }

        let nanosecondsUntilRefresh = nextUpdateInNanoseconds(for: accessTokenExpirationDate.timeIntervalSinceNow)

        // there's already an update scheduled, replace it if we need to refresh sooner
        if let nextScheduledUpdateInNanoseconds,
           (nanosecondsUntilRefresh + Self.scheduleToleranceInNanoseconds) > nextScheduledUpdateInNanoseconds {
                return
        }

        // check if an update recently completed within the tolerance window
        if let lastUpdateCompletedAt,
           nanosecondsUntilRefresh >= lastUpdateCompletedAt {
                return
        }

        nextScheduledUpdateInNanoseconds = nanosecondsUntilRefresh
        
        updateTask?.cancel()
        updateTask = Task {
            logDebug("Scheduled auth state update in \(nanosecondsUntilRefresh / 1_000_000_000) seconds")
            try await Task.sleep(nanoseconds: nanosecondsUntilRefresh)
            logDebug("Starting auth state update")
            try Task.checkCancellation()
            clearScheduledUpdate()
            await updateAuthStates()
            lastUpdateCompletedAt = nanosecondsUntilRefresh
        }
    }
    
    func updateAuthStates() async {
        logDebug("updateTokens")
        // Capture the reference before entering task group
        let accounts = authUtil.activeUsernames
        let authUtilRef = authUtil

        guard !accounts.isEmpty else {
            logDebug("No accounts to refresh")
            return
        }

        await withTaskGroup(of: Void.self) { group in
            for account in accounts {
                group.addTask { [weak self] in
                    guard let self else { return }
                    self.logDebug("Refreshing access token for \(account)")
                    do {
                        let _ = try await authUtilRef.getValidAccessToken(username: account, forceRefresh: true)
                        self.logDebug("Successfully refreshed token for \(account)")
                        await self.resetRetryAttempts(for: account)
                    } catch {
                        // Always log the error for debugging
                        self.logDebug("Failed to refresh token for \(account)", error: error)

                        // Capture unexpected errors in Sentry
                        if AuthError.shouldBeCaptured(error) {
                            await Logger.shared.authFailure(
                                username: account,
                                flowType: .backgroundRefresh,
                                error: error
                            )
                        }

                        if let authError = error as? AuthError,
                            case .tokenRefreshFailed(_, _, let requiresReauth) = authError {
                            if !requiresReauth {
                                // Recoverable error - schedule retry
                                self.logDebug("Recoverable error for \(account), scheduling retry", error: error)
                                await self.scheduleRetry(for: account)
                            } else {
                                // Unrecoverable error - requires reauth, no retry
                                self.logDebug("Unrecoverable error for \(account), requires reauth", error: error)
                                await self.resetRetryAttempts(for: account)
                            }
                        } else {
                            self.logDebug("Failed to refresh token for \(account)", error: error)
                        }
                    }
                }
            }

            for await _ in group { }
        }

        logDebug("All token refresh operations completed")
    }

    private func calculateBackoff(attempt: Int) -> TimeInterval {
        let exponentialDelay = baseRetryInterval * pow(2.0, Double(attempt))
        return min(exponentialDelay, maxRetryInterval)
    }

    private func scheduleRetry(for username: String) {
        let currentAttempt = retryAttempts[username] ?? 0
        retryAttempts[username] = currentAttempt + 1

        let retryDelay = calculateBackoff(attempt: currentAttempt)
        let retryDelayNanoseconds = UInt64(retryDelay * 1_000_000_000)

        logDebug("Scheduling retry for \(username) in \(retryDelay) seconds (attempt \(currentAttempt + 1))")

        Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: retryDelayNanoseconds)
                self.logDebug("Retrying token refresh for \(username)")
                _ = try await self.authUtil.getValidAccessToken(username: username, forceRefresh: true)
                self.logDebug("Retry successful for \(username)")
                await self.resetRetryAttempts(for: username)
            } catch {
                // Always log the error for debugging
                self.logDebug("Retry failed for \(username) (attempt \(currentAttempt + 1))", error: error)

                // Capture unexpected errors in Sentry
                if AuthError.shouldBeCaptured(error) {
                    await Logger.shared.authFailure(
                        username: username,
                        flowType: .backgroundRefreshRetry,
                        error: error,
                        additionalContext: [.retryAttempt: currentAttempt + 1]
                    )
                }

                if let authError = error as? AuthError,
                   case .tokenRefreshFailed(_, _, let requiresReauth) = authError {
                    if !requiresReauth {
                        await self.scheduleRetry(for: username)
                    } else {
                        self.logDebug("Retry failed with unrecoverable error for \(username)", error: error)
                        await self.resetRetryAttempts(for: username)
                    }
                } else {
                    self.logDebug("Retry failed for \(username)", error: error)
                }
            }
        }
    }

    private func resetRetryAttempts(for username: String) {
        retryAttempts[username] = nil
    }
    
    nonisolated private func logDebug(_ message: String, error: (any Error)? = nil) {
        Logger.shared.log(level: .debug, tag: "AuthStateUpdater", message: message, error: error)
    }
    
    nonisolated private func logError(_ message: String, error: (any Error)? = nil) {
        Logger.shared.event(level: .error, tag: "AuthStateUpdater", message: message, error: error)
    }
}

// MARK: - Background Updates
extension AuthStateUpdater {
    static let taskId = "com.geotab.mobile.sdk.authstate"
    
    nonisolated func initializeBackgroundUpdates() {
        backgroundStateListener = NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    self.logDebug("Entered background")
                    await self.scheduleBackgroundUpdate()
                }
            }
    }
    
    nonisolated func registerForBackgroundUpdates() {
        let result = backgroundScheduler.register(forTaskWithIdentifier: Self.taskId, using: nil) { [weak self] task in
            Task {
                guard let self else { return }
                guard let refreshTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    self.logError("Unknown background task type")
                    return
                }
                await self.handleAppRefresh(task: refreshTask)
            }
        }
        
        if result {
            logDebug("Background task registered for \(Self.taskId)")
            Task { [weak self] in await self?.setAsRegisteredForBackgroundRefresh() }
        } else {
            logError("Background task registrarion failed for \(Self.taskId)")
        }
    }
    
    func setAsRegisteredForBackgroundRefresh() {
        registeredForBackgroundRefresh = true
    }
    
    func scheduleBackgroundUpdate() {
        guard let nextScheduledUpdateInNanoseconds else { return }
        
        guard registeredForBackgroundRefresh else {
            logError("Schedule background update before registration")
            return
        }
        
        let nextScheduledUpdateInSeconds = Double(nextScheduledUpdateInNanoseconds) / 1_000_000_000
        let request = BGAppRefreshTaskRequest(identifier: Self.taskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: nextScheduledUpdateInSeconds)

        do {
            try backgroundScheduler.submit(request)
            logDebug("Background update scheduled")
        } catch {
            logError("Could not schedule background update", error: error)
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) async {
        await updateAuthStates()
        Task { [weak self] in
            guard let self else { return }
            try await Task.sleep(nanoseconds: Self.rescheduleDelayInNanoseconds)
            await scheduleBackgroundUpdate()
            task.setTaskCompleted(success: true)
        }
    }
}

extension BGTaskScheduler: BackgroundScheduling { }
