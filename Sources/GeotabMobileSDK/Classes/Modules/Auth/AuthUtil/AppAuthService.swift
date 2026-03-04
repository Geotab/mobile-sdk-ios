import AppAuth

protocol AppAuthService {
    func discoverConfiguration(forDiscoveryURL discoveryURL: URL) async throws -> OIDServiceConfiguration
    @MainActor func authState(byPresenting authorizationRequest: OIDAuthorizationRequest, session: OIDExternalUserAgentIOS) async throws -> (authState: OIDAuthState?, session: (any OIDExternalUserAgentSession)?)
    func getValidAccessToken(key: String, authState: OIDAuthState) async throws -> String
    func revokeToken(authState: OIDAuthState) async throws
    @MainActor func presentEndSession(request: OIDEndSessionRequest, presenting: UIViewController) async throws -> (any OIDExternalUserAgentSession)?
}

final class DefaultAppAuthService: AppAuthService {

    func discoverConfiguration(forDiscoveryURL discoveryURL: URL) async throws -> OIDServiceConfiguration {
        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.discoverConfiguration(forDiscoveryURL: discoveryURL) { configuration, error in
                if let configuration {
                    continuation.resume(returning: configuration)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: GeotabDriveErrors.AuthFailedError(error: AuthError.noDataFoundError.localizedDescription))
                }
            }
        }
    }
    
    @MainActor
    func authState(byPresenting authorizationRequest: OIDAuthorizationRequest, session: OIDExternalUserAgentIOS) async throws -> (authState: OIDAuthState?, session: (any OIDExternalUserAgentSession)?) {
        return try await withCheckedThrowingContinuation { continuation in
            var authSession: (any OIDExternalUserAgentSession)?
            authSession = OIDAuthState.authState(byPresenting: authorizationRequest, externalUserAgent: session) { authState, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (authState: authState, session: authSession))
                }
            }
        }
    }
    
    func getValidAccessToken(key: String, authState: OIDAuthState) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            authState.performAction(freshTokens: { accessToken, idToken, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let accessToken, !accessToken.isEmpty {
                    continuation.resume(returning: accessToken)
                } else {
                    continuation.resume(throwing: GetTokenError.noAccessTokenFoundError(key))
                }
            })
        }
    }
    
    func revokeToken(authState: OIDAuthState) async throws {
        guard let tokenToRevoke = authState.refreshToken else {
            throw LogoutError.noAuthorizationServiceInitialized
        }
        
        guard let discoveryDictionary = authState.lastAuthorizationResponse.request.configuration.discoveryDocument?.discoveryDictionary,
              let revocationEndpointString = discoveryDictionary["revocation_endpoint"] as? String,
              let revocationEndpoint = URL(string: revocationEndpointString) else {
            throw LogoutError.noAuthorizationServiceInitialized
        }
        
        let clientID = authState.lastAuthorizationResponse.request.clientID
        
        var request = URLRequest(url: revocationEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "token", value: tokenToRevoke),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "token_type_hint", value: "refresh_token")
        ]
        request.httpBody = components.query?.data(using: .utf8)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LogoutError.revokeTokenFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LogoutError.unexpectedResponse(httpResponse.statusCode)
        }
    }
    
    @MainActor
    func presentEndSession(request: OIDEndSessionRequest, presenting: UIViewController) async throws -> (any OIDExternalUserAgentSession)? {
        guard let agent = OIDExternalUserAgentIOS(presenting: presenting) else {
            throw LogoutError.noExternalUserAgent
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var session: (any OIDExternalUserAgentSession)?
            session = OIDAuthorizationService.present(request, externalUserAgent: agent) { _, error in
                if let error = error as? NSError {
                    if error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue {
                        continuation.resume(throwing: LogoutError.userCancelledLogoutFlow)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(returning: session)
                }
            }
        }
    }
}
