import Foundation
import AppAuth

enum AuthError: LocalizedError, JsonSerializableError, Equatable {
    case sessionParseFailedError
    case sessionRetrieveFailedError
    case unexpectedError(description: String, underlyingError: (any Error)?)
    case noDataFoundError
    case invalidURL
    case invalidRedirectScheme(String)
    case failedToSaveAuthState(username: String, underlyingError: any Error)
    case usernameMismatch(expected: String, actual: String)
    case noAccessTokenFoundError(String)
    case parseFailedForAuthState
    case tokenRefreshFailed(username: String, underlyingError: any Error, requiresReauthentication: Bool)
    case missingAuthData
    case noExternalUserAgent
    case revokeTokenFailed
    case unexpectedResponse(Int)
    case networkError(any Error)
    case userCancelledFlow

    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.sessionParseFailedError, .sessionParseFailedError):
            return true
        case (.sessionRetrieveFailedError, .sessionRetrieveFailedError):
            return true
        case (.unexpectedError(let lhsDesc, _), .unexpectedError(let rhsDesc, _)):
            return lhsDesc == rhsDesc
        case (.noDataFoundError, .noDataFoundError):
            return true
        case (.invalidURL, .invalidURL):
            return true
        case (.invalidRedirectScheme(let lhsScheme), .invalidRedirectScheme(let rhsScheme)):
            return lhsScheme == rhsScheme
        case (.failedToSaveAuthState(let lhsUsername, _), .failedToSaveAuthState(let rhsUsername, _)):
            return lhsUsername == rhsUsername
        case (.usernameMismatch(let lhsExpected, let lhsActual), .usernameMismatch(let rhsExpected, let rhsActual)):
            return lhsExpected == rhsExpected && lhsActual == rhsActual
        case (.noAccessTokenFoundError(let lhsUser), .noAccessTokenFoundError(let rhsUser)):
            return lhsUser == rhsUser
        case (.parseFailedForAuthState, .parseFailedForAuthState):
            return true
        case (.tokenRefreshFailed(let lhsUsername, _, let lhsRequiresReauth),
              .tokenRefreshFailed(let rhsUsername, _, let rhsRequiresReauth)):
            return lhsUsername == rhsUsername && lhsRequiresReauth == rhsRequiresReauth
        case (.missingAuthData, .missingAuthData):
            return true
        case (.noExternalUserAgent, .noExternalUserAgent):
            return true
        case (.revokeTokenFailed, .revokeTokenFailed):
            return true
        case (.unexpectedResponse(let lhsCode), .unexpectedResponse(let rhsCode)):
            return lhsCode == rhsCode
        case (.networkError, .networkError):
            return true
        case (.userCancelledFlow, .userCancelledFlow):
            return true
        default:
            return false
        }
    }

    var asJson: String? {
        toJson(AuthErrorResponse(from: self))
    }

    var errorDescription: String? {
        asJson ?? fallbackErrorMessage
    }

    var fallbackErrorMessage: String {
        switch self {
        case .sessionParseFailedError:
            return "Failed parsing session."
        case .sessionRetrieveFailedError:
            return "Failed retrieving session."
        case .unexpectedError(let description, let underlyingError):
            if let underlyingError {
                return "An unexpected authentication error occurred: \(description). \(underlyingError.localizedDescription)"
            } else {
                return "An unexpected authentication error occurred: \(description)"
            }
        case .noDataFoundError:
            return "No data returned from authorization flow."
        case .invalidURL:
            return "Insecure Discovery URI. HTTPS is required."
        case .invalidRedirectScheme(let schemeKey):
            return "Login redirect scheme key \(schemeKey) not found in Info.plist."
        case .failedToSaveAuthState(let username, let underlyingError):
            return "Failed to save auth state for user \(username): \(underlyingError.localizedDescription)"
        case .usernameMismatch(let expected, let actual):
            return "Username mismatch: expected '\(expected)' but access token contains '\(actual)'"
        case .noAccessTokenFoundError(let user):
            return "No auth token found for user \(user)"
        case .parseFailedForAuthState:
            return "Failed to unarchive auth state from Keychain data."
        case .tokenRefreshFailed(let username, let underlyingError, let requiresReauth):
            if requiresReauth {
                return "Token refresh failed for user \(username). Re-authentication required: \(underlyingError.localizedDescription)"
            } else {
                return "Token refresh failed for user \(username). Please try again: \(underlyingError.localizedDescription)"
            }
        case .missingAuthData:
            return "Missing required authentication data"
        case .noExternalUserAgent:
            return "No external user agent available to present authentication flow"
        case .revokeTokenFailed:
            return "Revoking token failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unexpectedResponse(let code):
            return "Unexpected response code: \(code)"
        case .userCancelledFlow:
            return "Authentication flow was cancelled"
        }
    }

    var errorCode: String {
        switch self {
        case .sessionParseFailedError:
            return "SESSION_PARSE_FAILED"
        case .sessionRetrieveFailedError:
            return "SESSION_RETRIEVE_FAILED"
        case .unexpectedError:
            return "UNEXPECTED_ERROR"
        case .noDataFoundError:
            return "NO_DATA_FOUND"
        case .invalidURL:
            return "INVALID_URL"
        case .invalidRedirectScheme:
            return "INVALID_REDIRECT_SCHEME"
        case .failedToSaveAuthState:
            return "FAILED_TO_SAVE_AUTH_STATE"
        case .usernameMismatch:
            return "USERNAME_MISMATCH"
        case .noAccessTokenFoundError:
            return "NO_ACCESS_TOKEN_FOUND"
        case .parseFailedForAuthState:
            return "PARSE_FAILED_FOR_AUTH_STATE"
        case .tokenRefreshFailed(_, _, let requiresReauth):
            return requiresReauth ? "TOKEN_REFRESH_REAUTH_REQUIRED" : "TOKEN_REFRESH_FAILED"
        case .missingAuthData:
            return "MISSING_AUTH_DATA"
        case .noExternalUserAgent:
            return "NO_EXTERNAL_USER_AGENT"
        case .revokeTokenFailed:
            return "REVOKE_TOKEN_FAILED"
        case .unexpectedResponse:
            return "UNEXPECTED_RESPONSE"
        case .networkError:
            return "NETWORK_ERROR"
        case .userCancelledFlow:
            return "USER_CANCELLED"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .tokenRefreshFailed(_, let error, _):
            return AuthError.isRecoverableError(error)
        case .networkError(let error):
            return AuthError.isRecoverableError(error)
        case .unexpectedError(_, let error):
            if let error = error {
                return AuthError.isRecoverableError(error)
            }
            return false
        case .unexpectedResponse(let statusCode):
            return statusCode >= 500 && statusCode < 600
        case .userCancelledFlow:
            return true
        default:
            return false
        }
    }

    static func isRecoverableError(_ error: any Error) -> Bool {
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

        if let authError = error as? AuthError {
            if case .unexpectedResponse(let statusCode) = authError {
                return statusCode >= 500 && statusCode < 600
            }
        }

        let nsError = error as NSError

        if nsError.domain == OIDOAuthTokenErrorDomain {
            return false
        }

        if nsError.domain == OIDGeneralErrorDomain {
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

        return false
    }

    static func isExpectedError(_ error: any Error) -> Bool {
        if let authError = error as? AuthError {
            switch authError {
            case .userCancelledFlow:
                return true
            case .networkError(let underlyingError):
                return isExpectedError(underlyingError)
            case .tokenRefreshFailed(_, let underlyingError, _):
                return isExpectedError(underlyingError)
            case .unexpectedError(_, let underlyingError):
                if let underlyingError {
                    return isExpectedError(underlyingError)
                }
                return false
            case .unexpectedResponse(let statusCode):
                return statusCode >= 500 && statusCode < 600
            default:
                return false
            }
        }

        let nsError = error as NSError

        if nsError.domain == OIDOAuthTokenErrorDomain {
            return true
        }

        if nsError.domain == OIDOAuthAuthorizationErrorDomain {
            return true
        }

        if nsError.domain == OIDGeneralErrorDomain {
            switch nsError.code {
            case OIDErrorCode.userCanceledAuthorizationFlow.rawValue:
                return true
            case OIDErrorCodeOAuth.invalidRequest.rawValue,
                 OIDErrorCodeOAuth.invalidClient.rawValue,
                 OIDErrorCodeOAuth.invalidGrant.rawValue,
                 OIDErrorCodeOAuth.unauthorizedClient.rawValue,
                 OIDErrorCodeOAuth.unsupportedGrantType.rawValue:
                return true
            default:
                return false
            }
        }

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

        return false
    }
}
