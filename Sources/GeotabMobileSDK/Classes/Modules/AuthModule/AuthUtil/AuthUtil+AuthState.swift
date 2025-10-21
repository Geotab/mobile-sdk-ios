import AppAuth
import UIKit
import Foundation

protocol KeychainServiceProtocol {
    func save(key: String, data: Data) -> OSStatus
    func load(key: String) -> (Data?, OSStatus)
    func delete(key: String) -> OSStatus
    var keys: [String] { get }
}

extension AuthUtil {
    var keys: [String] { keychainServiceConfigure.keys }
    
    func getValidAccessToken(key: String, completion: @escaping (Result<String, any Error>) -> Void) {
        getValidAccessToken(key: key, forceRefresh: false, completion: completion)
    }
    
    func getValidAccessToken(key: String, forceRefresh: Bool, completion: @escaping (Result<String, any Error>) -> Void) {
        
        //load auth state from keychain
        loadAuthState(key: key) { [weak self] authState, error in
            
            guard let self else { return }
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let authState else {
                completion(.failure(GetTokenError.noAccessTokenFoundError(key)))
                return
            }
            
            if forceRefresh {
                authState.setNeedsTokenRefresh()
            }
            
            appAuthService.getValidAccessToken(key: key, authState: authState) { result in
                
                switch result {
                case .success(let accessToken):
                    do {
                        // Save updated auth state back to Keychain
                        self.saveAuthState(key: key, authState: authState)
                        let tokenResponse = GeotabAppAuthResponse(accessToken: accessToken, idToken: nil, refreshToken: nil)
                        let jsonData = try JSONEncoder().encode(tokenResponse)
                        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                        completion(.success(jsonString))
                    } catch {
                        self.deleteAuthState(key: key)
                        self.$logger.error( "Token refresh failed for key: \(key) \(error)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    self.deleteAuthState(key: key)
                    self.$logger.error( "Token refresh failed for key: \(key) \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func saveAuthState(key: String, authState: OIDAuthState? = nil) {
        
        guard let authState else { return }
        
        notify(user: key, authState: authState)
        
        do {
            let authStateData = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
            
            let status = keychainServiceConfigure.save(key: key, data: authStateData)
            
            if status != errSecSuccess {
                $logger.error( "Failed to save authState for key: \(key) \(GetTokenError.failedToSaveAuthState)")
            }
            
        } catch {
            $logger.error( "Failed to save authState for key: \(key) \(error)")
        }
    }
    
    func loadAuthState(key: String, completion: @escaping (OIDAuthState?, (any Error)?) -> Void) {
        let (data, status) = keychainServiceConfigure.load(key: key)
        
        guard status == errSecSuccess else {
            completion(nil, GetTokenError.noAccessTokenFoundError(key))
            return
        }
        
        guard let data else {
            completion(nil, GetTokenError.parseFailedForAuthState)
            return
        }
        
        do {
            if let authState = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) {
                completion(authState, nil)
            } else {
                completion(nil, GetTokenError.parseFailedForAuthState)
            }
        } catch {
            completion(nil, error)
        }
    }
    
    func deleteAuthState(key: String) {
        let status = keychainServiceConfigure.delete(key: key)
        
        if status != errSecSuccess {
            $logger.error("Failed to delete key: \(key) \(GetTokenError.failedToDeleteAuthState)")
        }
    }
}
