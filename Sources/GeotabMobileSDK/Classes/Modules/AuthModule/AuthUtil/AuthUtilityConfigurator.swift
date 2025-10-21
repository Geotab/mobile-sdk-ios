import UIKit
import AppAuth
import Combine

protocol AuthUtilityConfigurator {
    func login(clientId: String, discoveryUri: URL, username: String, redirectUri: URL, ephemeralSession: Bool, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func discoverConfiguration(for discoveryUri: URL, completion: @escaping (Result<OIDServiceConfiguration, any Error>) -> Void)
    func handleConfigurationResult(clientID: String, username: String, redirectUri: URL, ephemeralSession: Bool, result: Result<OIDServiceConfiguration, any Error>, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func handleDiscoveryError(error: any Error, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func createAuthorizationRequestAndPresent(configuration: OIDServiceConfiguration, clientId: String, username: String, redirectUri: URL, ephemeralSession: Bool, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func buildAdditionalParameters(username: String) -> [String: String]?
    func buildAuthorizationRequest(configuration: OIDServiceConfiguration, clientId: String, redirectUri: URL, additionalParameters: [String: String]?) -> OIDAuthorizationRequest
    func presentAuthorization(request: OIDAuthorizationRequest,ephemeralSession: Bool, completion: @escaping (Result<OIDAuthState?, any Error>) -> Void)
    func handleAuthorizationResult(result: Result<OIDAuthState?, any Error>, key: String, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func handleAuthorizationError(error: (any Error)?, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func createAuthResponseAndCallback(authState: OIDAuthState, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func processAuthState(authState: OIDAuthState?, loginCallback: @escaping (Result<String, any Error>) -> Void)
    func buildGeotabAuthResponse(from authState: OIDAuthState) -> GeotabAppAuthResponse?
    func getValidAccessToken(key: String, completion: @escaping (Result<String, any Error>) -> Void)
    func getValidAccessToken(key: String, forceRefresh: Bool, completion: @escaping (Result<String, any Error>) -> Void)
    func saveAuthState(key: String, authState: OIDAuthState?)
    func loadAuthState(key: String, completion: @escaping (OIDAuthState?, (any Error)?) -> Void)
    func deleteAuthState(key: String)
    func logOut(userName: String, presentingViewController: UIViewController?, completion: @escaping (Result<String, any Error>) -> Void)
    func logoutUserAndDeleteToken(userName: String, authState: OIDAuthState, presentingViewController: UIViewController?) -> Future<String, any Error>
    func launchLogoutUser(userName: String, authState: OIDAuthState, presenting: UIViewController?) -> Future<String, any Error>
    var keys: [String] { get }
    // Temporary
    var returnAllTokensOnLogin: Bool { get set }
}

