import AppAuth
import UIKit
import Foundation
import Combine

struct GeotabAppAuthResponse: Codable {
    let accessToken: String
}

class AuthUtil: AuthUtilityConfigurator {
    
    var currentAuthorizationFlow: (any OIDExternalUserAgentSession)?
    let appAuthService: any AppAuthServiceConfigurator
    let keychainServiceConfigure: any KeychainServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    @TaggedLogger("AuthUtil")
    var logger
    
    init(appAuthService: any AppAuthServiceConfigurator = AppAuthService(), keychainService: any KeychainServiceProtocol = DefaultKeychainService()) {
        self.appAuthService = appAuthService
        self.keychainServiceConfigure = keychainService
    }
    
    // MARK: - Login Method
    func login(clientId: String, discoveryUri: URL, loginHint: String, redirectUri: URL, ephemeralSession: Bool, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        discoverConfiguration(for: discoveryUri) { [weak self] configurationResult in
            guard let self else { return }
            handleConfigurationResult(clientID: clientId, loginHint: loginHint , redirectUri: redirectUri, ephemeralSession: ephemeralSession, result: configurationResult, loginCallback: loginCallback)
        }
    }
    
    func discoverConfiguration(for discoveryUri: URL, completion: @escaping (Result<OIDServiceConfiguration, any Error>) -> Void) {
        appAuthService.discoverConfiguration(forDiscoveryURL: discoveryUri) { configuration, error in
            if let configuration {
                completion(.success(configuration))
            } else if let error {
                completion(.failure(error))
            }
        }
    }
    
    func handleConfigurationResult(clientID: String, loginHint: String, redirectUri: URL, ephemeralSession: Bool , result: Result<OIDServiceConfiguration, any Error>, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        switch result {
            
        case .success(let configuration):
            createAuthorizationRequestAndPresent(configuration: configuration, clientId: clientID, loginHint: loginHint, redirectUri: redirectUri, ephemeralSession: ephemeralSession , loginCallback: loginCallback)
        case .failure(let error):
            handleDiscoveryError(error: error, loginCallback: loginCallback)
        }
    }
    
    func handleDiscoveryError(error: any Error, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        loginCallback(.failure(GeotabDriveErrors.AuthFailedError(error: error.localizedDescription)))
    }
    
    func createAuthorizationRequestAndPresent(configuration: OIDServiceConfiguration, clientId: String, loginHint: String, redirectUri: URL, ephemeralSession: Bool, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        let additionalParameters = buildAdditionalParameters(loginHint: loginHint)
        let request = buildAuthorizationRequest(configuration: configuration, clientId: clientId, redirectUri: redirectUri, additionalParameters: additionalParameters)
        presentAuthorization(request: request, ephemeralSession: ephemeralSession) { [weak self] authStateResult in
            guard let self else { return }
            self.handleAuthorizationResult(result: authStateResult, key: loginHint, loginCallback: loginCallback)
        }
    }
    
    func buildAdditionalParameters(loginHint: String) -> [String: String]? {
        guard !loginHint.isEmpty else { return nil }
        return ["login_hint" : loginHint]
    }
    
    func buildAuthorizationRequest(configuration: OIDServiceConfiguration, clientId: String, redirectUri: URL, additionalParameters: [String: String]?) -> OIDAuthorizationRequest {
        return OIDAuthorizationRequest(
            configuration: configuration,
            clientId: clientId,
            scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
            redirectURL: redirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: additionalParameters )
    }
    
    func presentAuthorization(request: OIDAuthorizationRequest,ephemeralSession: Bool, completion: @escaping (Result<OIDAuthState?, any Error>) -> Void) {
        let viewPresenter = UIApplication.shared.rootViewController
        guard let externalUserAgent = OIDExternalUserAgentIOS(
            presenting: viewPresenter,
            prefersEphemeralSession: ephemeralSession
        )else { return }
        
        currentAuthorizationFlow = appAuthService.authState(byPresenting: request, session: externalUserAgent) { authState, error in
            if let authState {
                completion( .success(authState))
            } else if let error = error as? NSError {
                if error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue{
                    completion(.failure(GeotabDriveErrors.AuthFailedError(error: "User cancelled flow")))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func handleAuthorizationResult(result: Result<OIDAuthState?, any Error>, key: String, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        switch result {
        case .success(let authState):
            self.saveAuthState(key: key, authState: authState)
            processAuthState(authState: authState, loginCallback: loginCallback)
        case .failure(let error):
            handleAuthorizationError(error: error, loginCallback: loginCallback)
        }
    }
    
    func handleAuthorizationError(error: (any Error)?, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        let finalError: any Error = {
            if let error {
                return error.localizedDescription.isEmpty ?
                GeotabDriveErrors.AuthFailedError(error: "Authorization failed") :
                error
            } else {
                return GeotabDriveErrors.AuthFailedError(error: AppAuthError.noDataFoundError.rawValue)
            }
        }()
        loginCallback(.failure(finalError))
    }
    
    func processAuthState(authState: OIDAuthState?, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        guard let authState else {
            loginCallback(.failure(GeotabDriveErrors.AuthFailedError(error: AppAuthError.noDataFoundError.rawValue)))
            return
        }
        createAuthResponseAndCallback(authState: authState, loginCallback: loginCallback)
    }
    
    func createAuthResponseAndCallback(authState: OIDAuthState, loginCallback: @escaping (Result<String, any Error>) -> Void) {
        guard let authResponse = buildGeotabAuthResponse(from: authState) else {
            loginCallback(.failure(GeotabDriveErrors.AuthFailedError(error: AppAuthError.parseFailedError.rawValue)))
            return
        }
        if let jsonString = toJson(authResponse) {
            loginCallback(.success(jsonString))
        } else {
            loginCallback(.failure(GeotabDriveErrors.AuthFailedError(error: AppAuthError.parseFailedError.rawValue)))
        }
    }
    
    func buildGeotabAuthResponse(from authState: OIDAuthState) -> GeotabAppAuthResponse? {
        guard let accessToken = authState.lastTokenResponse?.accessToken else {
            return nil
        }
        return GeotabAppAuthResponse(
            accessToken: accessToken
        )
    }
}
