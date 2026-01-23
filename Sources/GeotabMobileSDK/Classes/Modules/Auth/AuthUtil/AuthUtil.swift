import AppAuth
import UIKit
import Foundation

// MARK: - Application State Provider
protocol ApplicationStateProviding {
    @MainActor var applicationState: UIApplication.State { get }
}

class DefaultApplicationStateProvider: ApplicationStateProviding {
    @MainActor var applicationState: UIApplication.State {
        return UIApplication.shared.applicationState
    }
}

// MARK: - View Presenter Provider
protocol ViewPresenterProviding {
    @MainActor func viewPresenter() throws -> UIViewController
}

class DefaultViewPresenterProvider: ViewPresenterProviding {
    @MainActor func viewPresenter() throws -> UIViewController {
        let presenter = UIApplication.shared.rootViewController
        guard presenter.view.window != nil else {
            throw AuthError.noExternalUserAgent
        }
        return presenter
    }
}

// MARK: - Protocol
protocol AuthUtil {
    func login(clientId: String, discoveryUri: URL, username: String, redirectUri: URL, ephemeralSession: Bool) async throws -> AuthTokens
    func reauth(username: String) async throws -> AuthTokens
    func getValidAccessToken(username: String) async throws -> AuthTokens
    func getValidAccessToken(username: String, forceRefresh: Bool) async throws -> AuthTokens
    func logOut(userName: String, presentingViewController: UIViewController?) async throws
    var activeUsernames: [String] { get }

    // temporary for LoginModule
    var returnAllTokensOnLogin: Bool { get set }
    var skipTokenPersistence: Bool { get set }
}

// MARK: - Static Keys
extension AuthUtil {
    static var authStateKey: String { "authState" }
    static var userKey: String { "user" }
}

// MARK: - Data Models
struct AuthTokens: Codable {
    let accessToken: String
    let idToken: String?
    let refreshToken: String?
}

struct AuthState: Codable {
    let oidAuthState: OIDAuthState
    let ephemeralSession: Bool
    
    init(oidAuthState: OIDAuthState, ephemeralSession: Bool) {
        self.oidAuthState = oidAuthState
        self.ephemeralSession = ephemeralSession
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case oidAuthStateData
        case ephemeralSession
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let authStateData = try NSKeyedArchiver.archivedData(withRootObject: oidAuthState, requiringSecureCoding: true)
        try container.encode(authStateData, forKey: .oidAuthStateData)
        try container.encode(ephemeralSession, forKey: .ephemeralSession)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let authStateData = try container.decode(Data.self, forKey: .oidAuthStateData)
        guard let oidAuthState = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: authStateData) else {
            throw AuthError.parseFailedForAuthState
        }
        self.oidAuthState = oidAuthState
        self.ephemeralSession = try container.decode(Bool.self, forKey: .ephemeralSession)
    }
}

// MARK: - Authorization Coordinator
actor AuthorizationCoordinator {
    private var inFlightLogins: [String: Task<AuthTokens, any Error>] = [:]
    private var inFlightReauths: [String: Task<AuthTokens, any Error>] = [:]
    private var inFlightTokenRefresh: [String: Task<AuthTokens, any Error>] = [:]
    private var inFlightLogouts: [String: Task<Void, any Error>] = [:]
    
    // Track any UI-presenting operation (login, reauth, logout) to serialize them
    private var currentUIOperation: Task<Any, any Error>?

    @TaggedLogger("AuthCoordinator")
    private var logger
    
    func performLogin(
        username: String,
        operation: @escaping () async throws -> AuthTokens
    ) async throws -> AuthTokens {
        // Check for existing login first, before waiting for UI operations
        if let existingTask = inFlightLogins[username] {
            $logger.debug("Login already in progress, sharing result")
            return try await existingTask.value
        }
        
        // Wait for any existing UI operation to complete
        await waitForUIOperation()
        
        $logger.debug("Starting new login")
        let task = Task<AuthTokens, any Error> {
            try await operation()
        }

        inFlightLogins[username] = task
        currentUIOperation = Task { try await task.value }

        defer { clearLogin(username: username) }
        let result = try await task.value
        currentUIOperation = nil
        return result
    }
    
    func performReauth(
        username: String,
        operation: @escaping () async throws -> AuthTokens
    ) async throws -> AuthTokens {
        // Check for existing reauth first, before waiting for UI operations
        if let existingTask = inFlightReauths[username] {
            $logger.debug("Re-authentication already in progress, sharing result")
            return try await existingTask.value
        }
        
        // Wait for any existing UI operation to complete
        await waitForUIOperation()
        
        $logger.debug("Starting new re-authentication")
        let task = Task<AuthTokens, any Error> {
            try await operation()
        }

        inFlightReauths[username] = task
        currentUIOperation = Task { try await task.value }

        defer { clearReauth(username: username) }
        let result = try await task.value
        currentUIOperation = nil
        return result
    }
    
    func performTokenRefresh(
        username: String,
        forceRefresh: Bool,
        operation: @escaping () async throws -> AuthTokens
    ) async throws -> AuthTokens {
        // Token refresh doesn't show UI, so no need to wait for UI operations
        let key = "\(username)_\(forceRefresh)"
        if let existingTask = inFlightTokenRefresh[key] {
            $logger.debug("Token refresh already in progress, sharing result")
            return try await existingTask.value
        }
        
        $logger.debug("Starting new token refresh")
        let task = Task<AuthTokens, any Error> {
            try await operation()
        }

        inFlightTokenRefresh[key] = task
        defer { clearTokenRefresh(key: key) }
        return try await task.value
    }
    
    func performLogout(
        username: String,
        operation: @escaping () async throws -> Void
    ) async throws {
        // Check for existing logout first, before waiting for UI operations
        if let existingTask = inFlightLogouts[username] {
            $logger.debug("Logout already in progress, waiting for completion")
            return try await existingTask.value
        }
        
        // Wait for any existing UI operation to complete
        await waitForUIOperation()
        
        $logger.debug("Starting new logout")
        let task = Task<Void, any Error> {
            try await operation()
        }

        inFlightLogouts[username] = task
        currentUIOperation = Task { try await task.value }

        defer { clearLogout(username: username) }
        try await task.value
        currentUIOperation = nil
    }
    
    private func waitForUIOperation() async {
        if let existingUIOperation = currentUIOperation {
            $logger.debug("Waiting for existing UI operation to complete")
            _ = try? await existingUIOperation.value
        }
    }
    
    private func clearLogin(username: String) {
        inFlightLogins[username] = nil
    }
    
    private func clearReauth(username: String) {
        inFlightReauths[username] = nil
    }
    
    private func clearTokenRefresh(key: String) {
        inFlightTokenRefresh[key] = nil
    }
    
    private func clearLogout(username: String) {
        inFlightLogouts[username] = nil
    }
}

final class DefaultAuthUtil: AuthUtil {
    var returnAllTokensOnLogin: Bool = false
    var skipTokenPersistence: Bool = false
    var currentAuthorizationFlow: (any OIDExternalUserAgentSession)?
    private let appAuthService: any AppAuthService
    private let authStateKeychainManager: any AuthKeychainManaging
    private let authCoordinator = AuthorizationCoordinator()
    private let applicationStateProvider: (any ApplicationStateProviding)
    private let viewPresenterProvider: (any ViewPresenterProviding)

    @TaggedLogger("AuthUtil")
    private var logger

    init(appAuthService: any AppAuthService = DefaultAppAuthService(),
             authStateKeychainManager: (any AuthKeychainManaging) = AuthKeychainManager(keychainService: DefaultKeychainService()),
             applicationStateProvider: (any ApplicationStateProviding)? = nil,
             viewPresenterProvider: (any ViewPresenterProviding)? = nil) {
            self.appAuthService = appAuthService
            self.authStateKeychainManager = authStateKeychainManager
            self.applicationStateProvider = applicationStateProvider ?? DefaultApplicationStateProvider()
            self.viewPresenterProvider = viewPresenterProvider ?? DefaultViewPresenterProvider()
    }
    
    // MARK: - Login Method
    func login(clientId: String, discoveryUri: URL, username: String, redirectUri: URL, ephemeralSession: Bool) async throws -> AuthTokens {
        return try await authCoordinator.performLogin(username: username) { [weak self] in
            guard let self else {
                throw AuthError.unexpectedError(description: "AuthUtil deallocated during login", underlyingError: nil)
            }

            do {
                // Discover OAuth configuration
                let configuration = try await self.appAuthService.discoverConfiguration(forDiscoveryURL: discoveryUri)

                // Perform authorization flow
                return try await self.performAuthorizationFlow(
                    configuration: configuration,
                    clientId: clientId,
                    redirectUri: redirectUri,
                    username: username,
                    ephemeralSession: ephemeralSession
                )
            } catch {
                throw AuthError.from(error, description: "Login failed with unexpected error")
            }
        }
    }

    // MARK: - Re-authentication Method
    func reauth(username: String) async throws -> AuthTokens {
        return try await authCoordinator.performReauth(username: username) { [weak self] in
            guard let self else {
                throw AuthError.unexpectedError(description: "AuthUtil deallocated during reauth", underlyingError: nil)
            }

            do {
                // Load existing auth state to get configuration and client info
                guard let existingAuthState = try self.authStateKeychainManager.loadAuthState(username: username) else {
                    throw AuthError.noAccessTokenFoundError(username)
                }

                let oidAuthState = existingAuthState.oidAuthState

                // Extract configuration from stored auth state
                let configuration = oidAuthState.lastAuthorizationResponse.request.configuration
                let clientId = oidAuthState.lastAuthorizationResponse.request.clientID

                guard let redirectUri = oidAuthState.lastAuthorizationResponse.request.redirectURL else {
                    throw AuthError.noAccessTokenFoundError(username)
                }

                // Use the stored ephemeralSession value
                let ephemeralSession = existingAuthState.ephemeralSession

                // Perform authorization flow
                return try await self.performAuthorizationFlow(
                    configuration: configuration,
                    clientId: clientId,
                    redirectUri: redirectUri,
                    username: username,
                    ephemeralSession: ephemeralSession,
                    flowType: .reauth
                )
            } catch let error as AuthError {
                // Check if user cancelled the reauth flow
                if case .userCancelledFlow = error {
                    // Clear all saved tokens for this user (don't log as auth failure)
                    self.$logger.debug("User cancelled reauth, clearing tokens for \(username)")
                    do {
                        try self.authStateKeychainManager.deleteAuthState(username: username)
                    } catch {
                        self.$logger.error("Failed to delete auth state after user cancellation: \(error)")
                    }
                    throw error
                }
                throw error
            } catch {
                throw AuthError.from(error, description: "Re-authentication failed with unexpected error")
            }
        }
    }
    
    // MARK: - Shared Authorization Flow
    private func performAuthorizationFlow(
        configuration: OIDServiceConfiguration,
        clientId: String,
        redirectUri: URL,
        username: String,
        ephemeralSession: Bool,
        flowType: Auth.FlowType = .login
    ) async throws -> AuthTokens {
        // Build authorization request
        let additionalParameters = username.isEmpty ? nil : ["login_hint": username]
        let request = buildAuthorizationRequest(
            configuration: configuration,
            clientId: clientId,
            redirectUri: redirectUri,
            additionalParameters: additionalParameters
        )

        // Present authorization flow
        let (oidAuthState, session) = try await presentAuthorization(request: request, ephemeralSession: ephemeralSession)
        currentAuthorizationFlow = session

        // Handle result
        guard let oidAuthState else {
            throw AuthError.noDataFoundError
        }

        // Validate username matches the one in the access token
        // Note: Username validation is conditional because empty username is valid in certain flows
        // (e.g., LoginModule where username comes from login_hint parameter in the auth flow itself)
        if !username.isEmpty {
            try await validateUsername(expected: username, in: oidAuthState)
        } else {
            $logger.debug("Skipping username validation - empty username provided")
        }

        // Wrap OIDAuthState with ephemeralSession flag
        let authState = AuthState(oidAuthState: oidAuthState, ephemeralSession: ephemeralSession)

        if !skipTokenPersistence {
            do {
                try authStateKeychainManager.saveAuthState(username: username, authState: authState)
            } catch {
                throw AuthError.failedToSaveAuthState(username: username, underlyingError: error)
            }
            notify(user: username, oidAuthState: oidAuthState)
        }

        return try createAuthResponse(from: oidAuthState)
    }
    
    private func buildAuthorizationRequest(configuration: OIDServiceConfiguration, clientId: String, redirectUri: URL, additionalParameters: [String: String]?) -> OIDAuthorizationRequest {
        return OIDAuthorizationRequest(
            configuration: configuration,
            clientId: clientId,
            scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
            redirectURL: redirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: additionalParameters )
    }
    
    private func presentAuthorization(request: OIDAuthorizationRequest, ephemeralSession: Bool) async throws -> (authState: OIDAuthState?, session: (any OIDExternalUserAgentSession)?) {
        let viewPresenter = try await viewPresenterProvider.viewPresenter()
        guard let externalUserAgent = OIDExternalUserAgentIOS(
            presenting: viewPresenter,
            prefersEphemeralSession: ephemeralSession
        ) else {
            throw AuthError.noExternalUserAgent
        }

        do {
            return try await appAuthService.authState(byPresenting: request, session: externalUserAgent)
        } catch {
            throw AuthError.from(error, description: "Authorization failed")
        }
    }
    
    private func createAuthResponse(from authState: OIDAuthState) throws -> AuthTokens {
        guard let authResponse = buildGeotabAuthResponse(from: authState) else {
            throw AuthError.unexpectedError(description: "Failed to build auth response from auth state", underlyingError: nil)
        }
        return authResponse
    }
    
    private func buildGeotabAuthResponse(from authState: OIDAuthState) -> AuthTokens? {
        guard let accessToken = authState.lastTokenResponse?.accessToken,
              !accessToken.isEmpty else {
            return nil
        }
        
        if returnAllTokensOnLogin {
            return AuthTokens(
                accessToken: accessToken,
                idToken: authState.lastTokenResponse?.idToken,
                refreshToken: authState.lastTokenResponse?.refreshToken)
        } else {
            return AuthTokens(
                accessToken: accessToken,
                idToken: nil,
                refreshToken: nil)
        }

    }
}

// MARK: - Auth State Management
extension DefaultAuthUtil {
    var activeUsernames: [String] { authStateKeychainManager.usernames }
    
    func getValidAccessToken(username: String) async throws -> AuthTokens {
        return try await getValidAccessToken(username: username, forceRefresh: false)
    }

    func getValidAccessToken(username: String, forceRefresh: Bool) async throws -> AuthTokens {
        return try await authCoordinator.performTokenRefresh(username: username, forceRefresh: forceRefresh) { [weak self] in
            guard let self else {
                throw AuthError.unexpectedError(description: "AuthUtil deallocated during token refresh", underlyingError: nil)
            }

            guard let authState = try self.authStateKeychainManager.loadAuthState(username: username) else {
                throw AuthError.noAccessTokenFoundError(username)
            }
            
            let oidAuthState = authState.oidAuthState
            
            if forceRefresh {
                oidAuthState.setNeedsTokenRefresh()
            }
            
            do {
                let accessToken = try await self.appAuthService.getValidAccessToken(key: username, authState: oidAuthState)
                // Update the wrapper with the refreshed OIDAuthState
                let updatedAuthState = AuthState(oidAuthState: oidAuthState, ephemeralSession: authState.ephemeralSession)
                do {
                    try self.authStateKeychainManager.saveAuthState(username: username, authState: updatedAuthState)
                } catch {
                    throw AuthError.failedToSaveAuthState(username: username, underlyingError: error)
                }
                self.notify(user: username, oidAuthState: oidAuthState)
                return AuthTokens(accessToken: accessToken, idToken: nil, refreshToken: nil)
            } catch {
                let isRecoverable = AuthError.isRecoverableError(error)

                if isRecoverable {
                    // Network error - keep auth state, user can retry
                    self.$logger.warn("Token refresh failed (recoverable): \(error)")
                    throw AuthError.tokenRefreshFailed(username: username, underlyingError: error, requiresReauthentication: false)
                } else {
                    // Auth server rejected the refresh token
                    self.$logger.warn("Token refresh failed (requires re-auth): \(error)")

                    // Check if app is in background - cannot show UI for reauth
                    let appState = await self.applicationStateProvider.applicationState
                    if appState == .background {
                        self.$logger.warn("App is in background, deferring reauth until foreground")
                        throw AuthError.tokenRefreshFailed(username: username, underlyingError: error, requiresReauthentication: true)
                    }

                    // App is in foreground, trigger re-auth
                    return try await self.reauth(username: username)
                }
            }
        }
    }
}

// MARK: - Logout
extension DefaultAuthUtil {
    func logOut(userName: String, presentingViewController: UIViewController?) async throws {
        try await authCoordinator.performLogout(username: userName) { [weak self] in
            guard let self else {
                throw AuthError.unexpectedError(description: "AuthUtil deallocated during logout", underlyingError: nil)
            }

            guard let authState = try self.authStateKeychainManager.loadAuthState(username: userName) else {
                let error = AuthError.noAccessTokenFoundError(userName)
                self.$logger.error("Failed to load auth state: \(error)")
                throw error
            }
            
            let oidAuthState = authState.oidAuthState
            
            // Revoke token
            do {
                try await self.appAuthService.revokeToken(authState: oidAuthState)
                self.$logger.debug("Token revoked successfully")
            } catch {
                self.$logger.error("Token revocation failed, continuing with logout: \(error)")
            }

            // Delete from keychain
            do {
                try self.authStateKeychainManager.deleteAuthState(username: userName)
            } catch {
                self.$logger.error("Failed to delete auth state: \(error)")
            }
            
            // Present end session if view controller available
            guard let presentingViewController else {
                self.$logger.error("View controller not available, logged out silently")
                return
            }

            do {
                self.currentAuthorizationFlow = try await self.presentEndSession(userName: userName, oidAuthState: oidAuthState, presenting: presentingViewController)
                self.$logger.debug("Logged out successfully")
            } catch {
                self.$logger.error("End session presentation failed: \(error)")
                throw AuthError.from(error, description: "Logout failed")
            }
        }
    }
    
    private func presentEndSession(userName: String, oidAuthState: OIDAuthState, presenting: UIViewController) async throws -> (any OIDExternalUserAgentSession)? {
        guard let idToken = oidAuthState.lastTokenResponse?.idToken,
              let postLogoutRedirectURL = oidAuthState.lastAuthorizationResponse.request.redirectURL else {
            $logger.error("No valid redirect URI, or ID token found in logout flow: \(AuthError.missingAuthData)")
            throw AuthError.missingAuthData
        }
        
        let serviceConfiguration = oidAuthState.lastAuthorizationResponse.request.configuration
        let endSessionRequest = OIDEndSessionRequest(
            configuration: serviceConfiguration,
            idTokenHint: idToken,
            postLogoutRedirectURL: postLogoutRedirectURL,
            additionalParameters: nil
        )
        
        return try await appAuthService.presentEndSession(request: endSessionRequest, presenting: presenting)
    }
}

// MARK: - Username Validation
extension DefaultAuthUtil {
    private func validateUsername(expected: String, in authState: OIDAuthState) async throws {
        guard let accessToken = authState.lastTokenResponse?.accessToken else {
            throw AuthError.unexpectedError(description: "No access token found in auth state", underlyingError: nil)
        }

        guard let actualUsername = extractUsername(from: accessToken) else {
            throw AuthError.unexpectedError(description: "Failed to extract username from access token", underlyingError: nil)
        }

        if actualUsername.trimmedLowercase != expected {
            do {
                try authStateKeychainManager.deleteAuthState(username: expected)
            } catch {
                $logger.error("Failed to delete auth state after username mismatch: \(error)")
            }

            try? await appAuthService.revokeToken(authState: authState)

            throw AuthError.usernameMismatch(expected: expected, actual: actualUsername)
        }
    }

    private func extractUsername(from jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else {
            return nil
        }

        let payloadPart = String(parts[1])
        guard let payloadData = base64UrlDecode(payloadPart) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }

        return json["preferred_username"] as? String
            ?? json["email"] as? String
            ?? json["sub"] as? String
    }

    private func base64UrlDecode(_ base64Url: String) -> Data? {
        var base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingLength = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: paddingLength)

        return Data(base64Encoded: base64)
    }
}

// MARK: - Notifications
extension DefaultAuthUtil {
    private func notify(user: String, oidAuthState: OIDAuthState) {
        NotificationCenter.default.post(name: .newAuthState,
                                        object: nil,
                                        userInfo: [
                                            DefaultAuthUtil.userKey: user,
                                            DefaultAuthUtil.authStateKey: oidAuthState
                                        ])
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let newAuthState = Notification.Name("GeotabMobileSDKNewAuthState")
}
