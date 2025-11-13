import Foundation
import AppAuth

protocol AuthKeychainManaging {
    func saveAuthState(username: String, authState: AuthState) throws
    func loadAuthState(username: String) throws -> AuthState?
    func deleteAuthState(username: String) throws
    var usernames: [String] { get }
}

final class AuthKeychainManager: AuthKeychainManaging {
    private let keychainService: any KeychainService

    @TaggedLogger("AuthKeychainManager")
    private var logger

    public init(keychainService: any KeychainService) {
        self.keychainService = keychainService
    }
    
    var usernames: [String] {
        return keychainService.keys
    }
    
    func saveAuthState(username: String, authState: AuthState) throws {
        do {
            let authStateData = try JSONEncoder().encode(authState)
            try keychainService.save(key: username, data: authStateData)
        } catch {
            $logger.error("Failed to save authState for username: \(username) - \(error)")
            throw error
        }
    }
    
    func loadAuthState(username: String) throws -> AuthState? {
        do {
            let data = try keychainService.load(key: username)
            let authState = try JSONDecoder().decode(AuthState.self, from: data)
            return authState
        } catch KeychainError.itemNotFound {
            return nil
        } catch {
            $logger.error("Failed to load authState for username: \(username) - \(error)")
            throw error
        }
    }
    
    func deleteAuthState(username: String) throws {
        do {
            try keychainService.delete(key: username)
        } catch {
            $logger.error("Failed to delete username: \(username) - \(error)")
            throw error
        }
    }
}