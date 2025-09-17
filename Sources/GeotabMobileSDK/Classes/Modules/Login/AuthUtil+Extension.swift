import AppAuth
import UIKit
import Foundation

protocol KeychainServiceProtocol {
    func save(key: String, data: Data) -> OSStatus
    func load(key: String) -> (Data?, OSStatus)
    func delete(key: String) -> OSStatus
}

extension AuthUtil {
    func getValidAccessToken(key: String, completion: @escaping (Result<String, any Error>) -> Void) {
        
        //load auth state from keychain
        loadAuthState(key: key) { [weak self] authState, error in
            
            guard let self else { return }
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let authState else {
                completion(.failure(GetAuthTokenErrror.noAccessTokenFoundError(key)))
                return
            }
            
            // Check if token needs refresh
            appAuthService.getValidAccessToken(key: key, authState: authState) { result in
                
                switch result {
                case .success(let accessToken):
                    do {
                        // Save updated auth state back to Keychain
                        self.saveAuthState(key: key, authState: authState)
                        let tokenResponse = GeotabAppAuthResponse(accessToken: accessToken)
                        let jsonData = try JSONEncoder().encode(tokenResponse)
                        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                        completion(.success(jsonString))
                    } catch {
                        self.deleteAuthState(key: key)
                        Logger.shared.event(level: .error, tag: "AuthUtil.getValidAccessToken" , message: "Token refresh failed for key: \(key)", error: error)
                        completion(.failure(error))
                    }
                case .failure(let error):
                    self.deleteAuthState(key: key)
                    Logger.shared.event(level: .error, tag: "AuthUtil.getValidAccessToken" , message: "Token refresh failed for key: \(key)", error: error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    func saveAuthState(key: String, authState: OIDAuthState? = nil) {
        
        guard let authState else { return }
        
        do {
            let authStateData = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
            
            let status = keychainServiceConfigure.save(key: key, data: authStateData)
            
            if status != errSecSuccess {
                Logger.shared.event(level: .error, tag: "AuthUtil.saveAuthState" , message: "Failed to save authState for key: \(key)", error: GetAuthTokenErrror.failedToSaveAuthState)
            }
            
        } catch {
            Logger.shared.event(level: .error, tag: "AuthUtil.saveAuthState" , message: "Failed to save authState for key: \(key)", error: error)
        }
    }
    
    func loadAuthState(key: String, completion: @escaping (OIDAuthState?, (any Error)?) -> Void) {
        let (data, status) = keychainServiceConfigure.load(key: key)
        
        guard status == errSecSuccess else {
            completion(nil, GetAuthTokenErrror.noAccessTokenFoundError(key))
            return
        }
        
        guard let data else {
            completion(nil, GetAuthTokenErrror.parseFailedForAuthState)
            return
        }
        
        do {
            if let authState = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) {
                completion(authState, nil)
            } else {
                completion(nil, GetAuthTokenErrror.parseFailedForAuthState)
            }
        } catch {
            completion(nil, error)
        }
    }
    
    func deleteAuthState(key: String) {
        let status = keychainServiceConfigure.delete(key: key)
        
        if status != errSecSuccess {
            Logger.shared.event(level: .error, tag: "AuthUtil.deleteAuthState", message: "Failed to delete key: \(key)", error: GetAuthTokenErrror.failedToDeleteAuthState)
        }
    }
}
