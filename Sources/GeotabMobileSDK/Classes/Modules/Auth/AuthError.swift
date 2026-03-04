import Foundation
import AppAuth

enum AuthError: LocalizedError, Equatable {
    case sessionParseFailedError
    case sessionRetrieveFailedError
    case parseFailedError
    case noDataFoundError
    case invalidURL
    case invalidRedirectScheme(String)
    case failedToSaveAuthState(username: String, underlyingError: any Error)

    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.sessionParseFailedError, .sessionParseFailedError):
            return true
        case (.sessionRetrieveFailedError, .sessionRetrieveFailedError):
            return true
        case (.parseFailedError, .parseFailedError):
            return true
        case (.noDataFoundError, .noDataFoundError):
            return true
        case (.invalidURL, .invalidURL):
            return true
        case (.invalidRedirectScheme(let lhsScheme), .invalidRedirectScheme(let rhsScheme)):
            return lhsScheme == rhsScheme
        case (.failedToSaveAuthState(let lhsUsername, _), .failedToSaveAuthState(let rhsUsername, _)):
            return lhsUsername == rhsUsername
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .sessionParseFailedError:
            return "Failed parsing session."
        case .sessionRetrieveFailedError:
            return "Failed retrieving session."
        case .parseFailedError:
            return "Failed parsing Json."
        case .noDataFoundError:
            return "No data returned from authorization flow."
        case .invalidURL:
            return "Insecure Discovery URI. HTTPS is required."
        case .invalidRedirectScheme(let schemeKey):
            return "Login redirect scheme key \(schemeKey) not found in Info.plist."
        case .failedToSaveAuthState(let username, let underlyingError):
            return "Failed to save auth state for user \(username): \(underlyingError.localizedDescription)"
        }
    }
}

enum GetTokenError: LocalizedError, Equatable {
    case noAccessTokenFoundError(String)
    case parseFailedForAuthState
    case failedToSaveAuthState
    case failedToDeleteAuthState
    case tokenRefreshFailed(username: String, underlyingError: any Error, requiresReauthentication: Bool)
    
    static func == (lhs: GetTokenError, rhs: GetTokenError) -> Bool {
        switch (lhs, rhs) {
        case (.noAccessTokenFoundError(let lhsUser), .noAccessTokenFoundError(let rhsUser)):
            return lhsUser == rhsUser
        case (.parseFailedForAuthState, .parseFailedForAuthState):
            return true
        case (.failedToSaveAuthState, .failedToSaveAuthState):
            return true
        case (.failedToDeleteAuthState, .failedToDeleteAuthState):
            return true
        case (.tokenRefreshFailed(let lhsUsername, _, let lhsRequiresReauth), 
              .tokenRefreshFailed(let rhsUsername, _, let rhsRequiresReauth)):
            return lhsUsername == rhsUsername && lhsRequiresReauth == rhsRequiresReauth
        default:
            return false
        }
    }
    
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
        case .tokenRefreshFailed(let username, let underlyingError, let requiresReauth):
            if requiresReauth {
                return "Token refresh failed for user \(username). Re-authentication required: \(underlyingError.localizedDescription)"
            } else {
                return "Token refresh failed for user \(username). Please try again: \(underlyingError.localizedDescription)"
            }
        }
    }
    
    /// Determines if an error from token refresh is recoverable (network issue) or requires re-authentication (auth server rejection)
    static func isRecoverableError(_ error: any Error) -> Bool {
        // Check for network errors (recoverable)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .timedOut,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed:
                return true
            default:
                return false
            }
        }
        
        // Check for HTTP 5xx server errors (recoverable - temporary server issue)
        if let logoutError = error as? LogoutError {
            if case .unexpectedResponse(let statusCode) = logoutError {
                return statusCode >= 500 && statusCode < 600
            }
        }
        
        // Check for NSError network errors
        let nsError = error as NSError
        
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorDNSLookupFailed:
                return true
            default:
                return false
            }
        }
        
        // Check for AppAuth OAuth errors
        if nsError.domain == OIDOAuthTokenErrorDomain {
            // OAuth errors like invalid_grant mean the refresh token is invalid - not recoverable
            return false
        }
        
        if nsError.domain == OIDGeneralErrorDomain {
            // General AppAuth errors (not OAuth protocol errors) might be network related
            // Check for specific codes that indicate auth issues
            switch nsError.code {
            case OIDErrorCodeOAuth.invalidRequest.rawValue,
                 OIDErrorCodeOAuth.invalidClient.rawValue,
                 OIDErrorCodeOAuth.invalidGrant.rawValue,
                 OIDErrorCodeOAuth.unauthorizedClient.rawValue,
                 OIDErrorCodeOAuth.unsupportedGrantType.rawValue:
                return false
            default:
                return true
            }
        }
        
        // Unknown errors are considered unrecoverable - safer to require re-auth
        return false
    }
}


enum LogoutError: LocalizedError, Equatable {
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
    
    static func == (lhs: LogoutError, rhs: LogoutError) -> Bool {
        switch (lhs, rhs) {
        case (.noAuthorizationServiceInitialized, .noAuthorizationServiceInitialized):
            return true
        case (.noUsersReturnedFromLogoutFlow, .noUsersReturnedFromLogoutFlow):
            return true
        case (.noExternalUserAgent, .noExternalUserAgent):
            return true
        case (.revokeTokenFailed, .revokeTokenFailed):
            return true
        case (.noAccessTokenFoundError(let lhsUser), .noAccessTokenFoundError(let rhsUser)):
            return lhsUser == rhsUser
        case (.unexpectedResponse(let lhsCode), .unexpectedResponse(let rhsCode)):
            return lhsCode == rhsCode
        case (.networkError, .networkError):
            return true  // Compare by case only, not underlying error
        case (.userCancelledLogoutFlow, .userCancelledLogoutFlow):
            return true
        case (.failedToCreateSessionRequest, .failedToCreateSessionRequest):
            return true
        case (.authUtilDeallocated, .authUtilDeallocated):
            return true
        default:
            return false
        }
    }
    
    
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
