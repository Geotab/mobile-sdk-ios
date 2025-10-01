import AppAuth
import Combine

protocol AuthStateUpdating {
    func start()
    func stop()
    func updateAuthStates() async
}

actor AuthStateUpdater: AuthStateUpdating {
    private static let scheduleToleranceInNanoseconds: UInt64 = 10 * 1_000_000_000
    
    @TaggedLogger("AuthStateUpdater")
    private var logger
    
    private let authUtil: any AuthUtilityConfigurator
    private let minimumScheduleInternal: TimeInterval
    
    private var updateTask: Task<Void, any Error>?
    private var nextScheduledUpdateInNanoseconds: UInt64?
    
    nonisolated(unsafe) private var newAuthStateListener: AnyCancellable?
    
    init(authUtil: any AuthUtilityConfigurator = AuthUtil(), minimumScheduleInternal: TimeInterval = 120) {
        self.authUtil = authUtil
        self.minimumScheduleInternal = minimumScheduleInternal
    }

    deinit {
        updateTask?.cancel()
        updateTask = nil
        nextScheduledUpdateInNanoseconds = nil
    }
    
    nonisolated func start() {
        newAuthStateListener = NotificationCenter.default
            .publisher(for: .newAuthState)
            .compactMap { notification in
                notification.userInfo?[AuthUtil.authStateKey] as? OIDAuthState
            }
            .sink { [weak self] authState in
                Task { await self?.scheduleUpdate(for: authState) }
            }
    }
    
    nonisolated func stop() {
        newAuthStateListener?.cancel()
    }
    
    nonisolated func computeNextScheduledUpdate(for expiration: TimeInterval) -> UInt64 {
        // 1/2 of the expiration time, with a minimum of 2 mins
        let expirationTimeInterval = expiration / 2
        return UInt64(max(expirationTimeInterval, minimumScheduleInternal)) * 1_000_000_000
    }
    
    private func scheduleUpdate(for authState:OIDAuthState) async {
        guard let accessTokenExpirationDate = authState.lastTokenResponse?.accessTokenExpirationDate else { return }
        
        let nanosecondsUntilRefresh = computeNextScheduledUpdate(for: accessTokenExpirationDate.timeIntervalSinceNow)
        
        // there's already an update scheduled, replace it if we need to refresh sooner
        if let nextScheduledUpdateInNanoseconds,
           (nanosecondsUntilRefresh + Self.scheduleToleranceInNanoseconds) > nextScheduledUpdateInNanoseconds {
                return
        }

        nextScheduledUpdateInNanoseconds = nanosecondsUntilRefresh
        
        updateTask?.cancel()
        updateTask = Task {
            $logger.debug("Scheduled auth state update in \(nanosecondsUntilRefresh / 1_000_000_000) seconds")
            try await Task.sleep(nanoseconds: nanosecondsUntilRefresh)
            $logger.debug("Starting auth state update")
            try Task.checkCancellation()
            updateTask = nil
            nextScheduledUpdateInNanoseconds = nil
            await updateAuthStates()
        }
    }
    
    func updateAuthStates() async {
        $logger.debug("updateTokens")
        for account in authUtil.keys {
            $logger.debug("Refreshing access token for \(account)")
            // this will cause newAuthState to fire and a new updateTask will be created
            authUtil.getValidAccessToken(key: account, forceRefresh: true, completion: { _ in } )
        }
    }
}
