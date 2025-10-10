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
    
    private let authUtil: any AuthUtilityConfigurator
    private let minimumScheduleInterval: TimeInterval
    
    private var updateTask: Task<Void, any Error>?
    private var nextScheduledUpdateInNanoseconds: UInt64?
    private var registeredForBackgroundRefresh = false
    
    nonisolated(unsafe) private var newAuthStateListener: AnyCancellable?
    nonisolated(unsafe) private var backgroundStateListener: AnyCancellable?
    nonisolated(unsafe) private let backgroundScheduler: any BackgroundScheduling
    nonisolated(unsafe) private let logger: any Logging

    init(authUtil: any AuthUtilityConfigurator = AuthUtil(),
         backgroundScheduler: any BackgroundScheduling = BGTaskScheduler.shared,
         logger: any Logging = Logger.shared,
         minimumScheduleInterval: TimeInterval = 120) {
        self.authUtil = authUtil
        self.backgroundScheduler = backgroundScheduler
        self.logger = logger
        self.minimumScheduleInterval = minimumScheduleInterval
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
                notification.userInfo?[AuthUtil.authStateKey] as? OIDAuthState
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

        nextScheduledUpdateInNanoseconds = nanosecondsUntilRefresh
        
        updateTask?.cancel()
        updateTask = Task {
            logDebug("Scheduled auth state update in \(nanosecondsUntilRefresh / 1_000_000_000) seconds")
            try await Task.sleep(nanoseconds: nanosecondsUntilRefresh)
            logDebug("Starting auth state update")
            try Task.checkCancellation()
            clearScheduledUpdate()
            await updateAuthStates()
        }
    }
    
    func updateAuthStates() async {
        logDebug("updateTokens")
        // Capture the reference before entering task group
        let accounts = authUtil.keys
        let authUtilRef = authUtil
        
        guard !accounts.isEmpty else {
            logDebug("No accounts to refresh")
            return
        }
        
        await withTaskGroup(of: Void.self) { group in
            for account in accounts {
                group.addTask { [weak self] in
                    self?.logDebug("Refreshing access token for \(account)")
                    
                    await withCheckedContinuation { continuation in
                        authUtilRef.getValidAccessToken(key: account, forceRefresh: true) { result in
                            switch result {
                            case .success(_):
                                self?.logDebug("Successfully refreshed token for \(account)")
                            case .failure(let error):
                                self?.logError("Failed to refresh token for \(account)", error: error)
                            }
                            continuation.resume()
                        }
                    }
                }
            }
            
            for await _ in group { }
        }
        
        logDebug("All token refresh operations completed")
    }
    
    nonisolated private func logDebug(_ message: String) {
        logger.log(level: .debug, tag: "AuthStateUpdater", message: message)
    }
    
    nonisolated private func logError(_ message: String, error: (any Error)? = nil) {
        logger.event(level: .error, tag: "AuthStateUpdater", message: message, error: error)
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
        Task {
            try await Task.sleep(nanoseconds: Self.rescheduleDelayInNanoseconds)
            scheduleBackgroundUpdate()
            task.setTaskCompleted(success: true)
        }
    }
}

extension BGTaskScheduler: BackgroundScheduling { }
