import Foundation

enum AppAuthError: String {
    case sessionParseFailedError = "Failed parsing session."
    case sessionRetrieveFailedError = "Failed retrieving session."
    case parseFailedError = "Failed parsing Json."
    case noDataFoundError = "No data returned from authorization flow."
    case invalidURL = "Insecure Discovery URI. HTTPS is required."
    case invalidRedirectScheme = "Login redirect scheme key [REPLACE] not found in Info.plist."
}
enum GetAuthTokenErrror: LocalizedError {
    case noAccessTokenFoundError(String)
    case parseFailedForAuthState
    case failedToSaveAuthState
    case failedToDeleteAuthState
    
    var errorDescription: String? {
        switch self {
        case .noAccessTokenFoundError(let user):
            return "No auth token found for user \(user)"
        case .parseFailedForAuthState:
            return "Failed to unarchive auth state from Keychain data."
        case .failedToSaveAuthState:
            return "Failed to save auth state to Keychain."
        case .failedToDeleteAuthState:
            return "Failed to delete auth state from Keychain."
        }
    }
}
