import Foundation

enum AppAuthError: String {
    case sessionParseFailedError = "Failed parsing session."
    case sessionRetrieveFailedError = "Failed retrieving session."
    case parseFailedError = "Failed parsing Json."
    case noDataFoundError = "No data returned from authorization flow."
    case invalidURL = "Insecure Discovery URI. HTTPS is required."
    case invalidRedirectScheme = "Login redirect scheme key [REPLACE] not found in Info.plist."
}
enum GetAuthTokenError: LocalizedError {
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


enum LogoutError: LocalizedError {
    case noAuthorizationServiceInitialized
    case noUsersReturnedFromLogoutFlow
    case noExternalUserAgent
    case revokeTokenFailed
    case noAccessTokenFoundError(String)
    case unexpectedResponse(Int)
    case networkError(any Error)
    case userCancelledLogoutFlow
    case failedToCreateSessionRequest
    case authUtilDeallocated
    
    
    var errorDescription: String? {
        switch self {
        case .noAuthorizationServiceInitialized:
            return "AuthorizationService not initialized"
        case .noUsersReturnedFromLogoutFlow:
            return "No username returned from logout flow"
        case .noExternalUserAgent:
            return "No external user agent available to present logout flow"
        case .revokeTokenFailed:
            return "Revoking token failed"
        case .noAccessTokenFoundError(let user):
            return "No valid token found for user \(user)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unexpectedResponse(let code):
            return "Unexpected response code: \(code)"
        case .userCancelledLogoutFlow:
            return "Logout failed or was cancelled"
        case .failedToCreateSessionRequest:
            return "Failed to create end session request"
        case .authUtilDeallocated:
            return "AuthUtil instance has been deallocated"
        }
    }
}
