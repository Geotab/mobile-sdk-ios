import AppAuth

typealias OIDServiceConfigurationCallback = (OIDServiceConfiguration?, (any Error)?) -> Void
typealias OIDAuthStateAuthorizationCallback = (OIDAuthState?, (any Error)?) -> Void
typealias OIDAuthStateValidAccessTokenCallback = ((Result<String, any Error>)) -> Void

// MARK: - AppAuthServiceConfigurator
protocol AppAuthServiceConfigurator {
    func discoverConfiguration(forDiscoveryURL discoveryURL: URL, completion: @escaping OIDServiceConfigurationCallback)
    func authState(byPresenting authorizationRequest: OIDAuthorizationRequest, session: OIDExternalUserAgentIOS, callback: @escaping OIDAuthStateAuthorizationCallback) -> (any OIDExternalUserAgentSession)?
    func getValidAccessToken(key:String, authState: OIDAuthState, completion: @escaping OIDAuthStateValidAccessTokenCallback)
}

// MARK: - AppAuthService
class AppAuthService: AppAuthServiceConfigurator {
    
    func discoverConfiguration(forDiscoveryURL discoveryURL: URL, completion: @escaping OIDServiceConfigurationCallback) {
        OIDAuthorizationService.discoverConfiguration(forDiscoveryURL: discoveryURL, completion: completion)
    }
    
    func authState(byPresenting authorizationRequest: OIDAuthorizationRequest, session: OIDExternalUserAgentIOS, callback: @escaping OIDAuthStateAuthorizationCallback) -> (any OIDExternalUserAgentSession)? {
        return OIDAuthState.authState(byPresenting: authorizationRequest, externalUserAgent: session, callback: callback)
    }
    
    func getValidAccessToken(key:String, authState: OIDAuthState, completion: @escaping OIDAuthStateValidAccessTokenCallback) {
        return authState.performAction(freshTokens: { accessToken, idToken, error in
           if let error {
                completion(Result.failure(error))
           } else {
               guard let accessToken else {
                   completion(Result.failure(GetTokenError.noAccessTokenFoundError(key)))
                   return
               }
            completion(Result.success(accessToken))
           }
        })
    }
}
