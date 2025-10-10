import Foundation
import AppAuth
import UIKit
import Combine

extension AuthUtil {
    
    func logOut(userName: String, presentingViewController: UIViewController?, completion: @escaping (Result<String, any Error>) -> Void) {
        
        // load logged user token from secure storage
        loadAuthState(key: userName) { [weak self] authState, error in
            
            guard let self else {
                self?.$logger.error("AuthUtil instance was deallocated during logout: \(LogoutError.authUtilDeallocated)")
                completion(.failure(LogoutError.authUtilDeallocated))
                return
            }
            
            if let error {
                $logger.error("Failed to load auth state: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let authState else {
                $logger.error("Failed to load auth state: \(LogoutError.noAccessTokenFoundError(userName))")
                completion(.failure(LogoutError.noAccessTokenFoundError(userName)))
                return
            }
            
            revokeToken(authState: authState)
                .catch { error -> Just<()> in
                    return Just(())
                }
                .receive(on: DispatchQueue.main)
                .flatMap { [weak self] _ -> Future<String, any Error> in
                    
                    guard let self else {
                        self?.$logger.error("AuthUtil instance was deallocated during logout: \(LogoutError.authUtilDeallocated)")
                        return Future { $0(.failure(LogoutError.authUtilDeallocated)) }
                    }
                    
                    return logoutUserAndDeleteToken(
                        userName: userName,
                        authState: authState,
                        presentingViewController: presentingViewController
                    )
                }
                .sink(receiveCompletion: { sinkCompletion in
                    if case .failure(let error) = sinkCompletion {
                        let finalError = error.localizedDescription.isEmpty ? LogoutError.failedToCreateSessionRequest : error
                        self.$logger.error("Token revocation failed: \(finalError)")
                        completion(.failure(finalError))
                    }
                }, receiveValue: { successMessage in
                    self.$logger.info("Token Revoked successfully")
                    completion(.success(successMessage))
                    
                })
                .store(in: &self.cancellables)
        }
    }
    
    func logoutUserAndDeleteToken(userName: String, authState: OIDAuthState, presentingViewController: UIViewController?) -> Future<String, any Error> {
        return Future { [weak self] promise in
            guard let self else {
                self?.$logger.error("AuthUtil instance was deallocated during logout: \(LogoutError.authUtilDeallocated)")
                promise(.failure(LogoutError.authUtilDeallocated))
                return
            }
            
            // delete token locally
            deleteAuthState(key: userName)
            
            launchLogoutUser(userName: userName, authState: authState, presenting: presentingViewController)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.$logger.error("Logged out failed for \(userName): \(error)")
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { successMessage in
                        self.$logger.info("Logged out successfully \(userName).")
                        promise(.success(successMessage))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    func launchLogoutUser(userName: String, authState: OIDAuthState, presenting: UIViewController?) -> Future<String, any Error> {
        return Future { [weak self] promise in
            guard let self else {
                self?.$logger.error("AuthUtil instance was deallocated during logout: \(LogoutError.authUtilDeallocated)")
                promise(.failure(LogoutError.authUtilDeallocated))
                return
            }
            
            guard let idToken = authState.lastTokenResponse?.idToken,
                  let postLogoutRedirectURL = authState.lastAuthorizationResponse.request.redirectURL else {
                self.$logger.error("No valid redirect URI, or ID token found in logout flow: \(LogoutError.noAuthorizationServiceInitialized)")
                promise(.failure(LogoutError.noAuthorizationServiceInitialized))
                return
            }
            
            guard let presenting else {
                self.$logger.info("View controller not available, logging out silently")
                promise(.success("Successfully logged out (no browser session to clear)"))
                return
            }
            
            let serviceConfiguration = authState.lastAuthorizationResponse.request.configuration
            let endSessionRequest = OIDEndSessionRequest(
                configuration: serviceConfiguration,
                idTokenHint: idToken,
                postLogoutRedirectURL: postLogoutRedirectURL,
                state: userName, additionalParameters: nil
            )
            
            guard let agent = OIDExternalUserAgentIOS(presenting: presenting) else  {
                self.$logger.error("User agent not available: \(LogoutError.noExternalUserAgent)")
                promise(.failure(LogoutError.noExternalUserAgent))
                return
            }
            currentAuthorizationFlow = OIDAuthorizationService.present(endSessionRequest, externalUserAgent: agent) { _, error in
                if let error = error as? NSError {
                    if error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue {
                        self.$logger.error("Logout failed: \(LogoutError.userCancelledLogoutFlow)")
                        promise(.failure(LogoutError.userCancelledLogoutFlow))
                    } else {
                        self.$logger.error("Logout failed: \(error)")
                        promise(.failure(error))
                    }
                } else {
                    self.$logger.info("View controller not available, logging out silently")
                    promise(.success("Successfully logged out"))
                }
            }
        }
    }
    
    private func revokeToken(authState: OIDAuthState) -> Future<Void, any Error> {
        return Future { promise in
            guard let tokenToRevoke = authState.refreshToken else {
                self.$logger.error("No valid token available to revoke: \(LogoutError.noAuthorizationServiceInitialized)")
                promise(.failure(LogoutError.noAuthorizationServiceInitialized))
                return
            }
            
            guard let discoveryDictionary = authState.lastAuthorizationResponse.request.configuration.discoveryDocument?.discoveryDictionary,
                  let revocationEndpointString = discoveryDictionary["revocation_endpoint"] as? String,
                  let revocationEndpoint = URL(string: revocationEndpointString) else {
                self.$logger.error("Authorization server configuration does not support token revocation: \(LogoutError.noAuthorizationServiceInitialized)")
                promise(.failure(LogoutError.noAuthorizationServiceInitialized))
                return
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
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error {
                    self.$logger.error("Network error during token revocation: \(error)")
                    promise(.failure(LogoutError.noAuthorizationServiceInitialized))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.$logger.error("An unexpected error occurred during token revocation: \( LogoutError.revokeTokenFailed)")
                    promise(.failure(LogoutError.revokeTokenFailed))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    self.$logger.error("Token revocation response code: \(httpResponse.statusCode)")
                    promise(.failure(LogoutError.unexpectedResponse(httpResponse.statusCode)))
                    return
                }
                self.$logger.info("Token revoked successfully")
                promise(.success(()))
            }.resume()
        }
    }
}
