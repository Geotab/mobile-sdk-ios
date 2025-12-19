import Foundation
import AppAuth

enum AuthError: LocalizedError, JsonSerializableError, Equatable {
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

    // OID error domain cases (from AppAuth-iOS)
    case oidGeneralError(code: Int, underlyingError: any Error)
    case oauthAuthorizationError(code: Int, description: String)
    case oauthTokenError(code: Int, description: String)

    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
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
        case (.oidGeneralError(let lhsCode, _), .oidGeneralError(let rhsCode, _)):
            return lhsCode == rhsCode
        case (.oauthAuthorizationError(let lhsCode, _), .oauthAuthorizationError(let rhsCode, _)):
            return lhsCode == rhsCode
        case (.oauthTokenError(let lhsCode, _), .oauthTokenError(let rhsCode, _)):
            return lhsCode == rhsCode
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
        case .oidGeneralError(let code, let underlyingError):
            let codeName = oidGeneralErrorName(code: code)
            return "AppAuth general error (\(codeName)): \(underlyingError.localizedDescription)"
        case .oauthAuthorizationError(let code, let description):
            return "OAuth authorization error (code \(code)): \(description)"
        case .oauthTokenError(let code, let description):
            return "OAuth token error (code \(code)): \(description)"
        }
    }

    // Helper to get human-readable OID error names
    private func oidGeneralErrorName(code: Int) -> String {
        switch code {
        case OIDErrorCode.invalidDiscoveryDocument.rawValue:
            return "invalid_discovery_document"
        case OIDErrorCode.userCanceledAuthorizationFlow.rawValue:
            return "user_canceled"
        case OIDErrorCode.programCanceledAuthorizationFlow.rawValue:
            return "program_canceled"
        case OIDErrorCode.networkError.rawValue:
            return "network_error"
        case OIDErrorCode.serverError.rawValue:
            return "server_error"
        case OIDErrorCode.jsonDeserializationError.rawValue:
            return "json_deserialization_error"
        case OIDErrorCode.tokenResponseConstructionError.rawValue:
            return "token_response_construction_error"
        case OIDErrorCode.safariOpenError.rawValue:
            return "safari_open_error"
        case OIDErrorCode.browserOpenError.rawValue:
            return "browser_open_error"
        case OIDErrorCode.tokenRefreshError.rawValue:
            return "token_refresh_error"
        case OIDErrorCode.registrationResponseConstructionError.rawValue:
            return "registration_response_construction_error"
        case OIDErrorCode.jsonSerializationError.rawValue:
            return "json_serialization_error"
        case OIDErrorCode.idTokenParsingError.rawValue:
            return "id_token_parsing_error"
        case OIDErrorCode.idTokenFailedValidationError.rawValue:
            return "id_token_validation_error"
        default:
            return "unknown_\(code)"
        }
    }

    var errorCode: String {
        switch self {
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
        case .oidGeneralError:
            return "OID_GENERAL_ERROR"
        case .oauthAuthorizationError:
            return "OAUTH_AUTHORIZATION_ERROR"
        case .oauthTokenError:
            return "OAUTH_TOKEN_ERROR"
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
        case .oidGeneralError(let code, _):
            // Network and server errors are recoverable, config/programming errors are not
            switch code {
            case OIDErrorCode.networkError.rawValue,
                 OIDErrorCode.serverError.rawValue:
                return true
            default:
                return false
            }
        case .oauthAuthorizationError, .oauthTokenError:
            return false  // OAuth protocol errors are not recoverable
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
            case OIDErrorCode.networkError.rawValue,
                 OIDErrorCode.serverError.rawValue:
                return true
            default:
                return false
            }
        }

        return false
    }

    /// Determines if an error should be captured in Sentry for investigation.
    /// Returns `true` for unexpected errors that indicate bugs, configuration issues, or system failures.
    static func shouldBeCaptured(_ error: any Error) -> Bool {
        if let authError = error as? AuthError {
            return shouldCaptureAuthError(authError)
        }
        return shouldCaptureNSError(error as NSError)
    }

    private static func shouldCaptureAuthError(_ error: AuthError) -> Bool {
        switch error {
        // User actions - don't capture
        case .userCancelledFlow:
            return false

        // Network errors - don't capture (expected operational issues)
        case .networkError:
            return false

        // HTTP errors - 5xx are expected, 4xx might indicate config issues
        case .unexpectedResponse(let statusCode):
            return statusCode >= 400 && statusCode < 500

        // No access token - expected when user not logged in
        case .noAccessTokenFoundError:
            return false

        // Wrapped errors - check underlying
        case .tokenRefreshFailed(_, let underlyingError, _):
            return shouldBeCaptured(underlyingError)

        case .unexpectedError(_, let underlyingError):
            if let underlyingError {
                return shouldBeCaptured(underlyingError)
            }
            return true

        // OID error cases
        case .oidGeneralError(let code, _):
            return shouldCaptureOIDGeneralError(code: code)

        case .oauthAuthorizationError(let code, _):
            return shouldCaptureOAuthAuthorizationError(code: code)

        case .oauthTokenError(let code, _):
            return shouldCaptureOAuthTokenError(code: code)

        // All other errors are unexpected and should be captured
        default:
            return true
        }
    }

    private static func shouldCaptureNSError(_ nsError: NSError) -> Bool {
        // URLError domain (network errors are expected)
        if nsError.domain == NSURLErrorDomain {
            return false
        }

        // OIDGeneralErrorDomain
        if nsError.domain == OIDGeneralErrorDomain {
            return shouldCaptureOIDGeneralError(code: nsError.code)
        }

        // OIDOAuthAuthorizationErrorDomain
        if nsError.domain == OIDOAuthAuthorizationErrorDomain {
            return shouldCaptureOAuthAuthorizationError(code: nsError.code)
        }

        // OIDOAuthTokenErrorDomain
        if nsError.domain == OIDOAuthTokenErrorDomain {
            return shouldCaptureOAuthTokenError(code: nsError.code)
        }

        // OIDHTTPErrorDomain
        if nsError.domain == OIDHTTPErrorDomain {
            return nsError.code >= 400 && nsError.code < 500
        }

        // Unknown errors should be captured
        return true
    }

    private static func shouldCaptureOIDGeneralError(code: Int) -> Bool {
        switch code {
        case OIDErrorCode.userCanceledAuthorizationFlow.rawValue,
             OIDErrorCode.programCanceledAuthorizationFlow.rawValue,
             OIDErrorCode.networkError.rawValue,
             OIDErrorCode.serverError.rawValue:
            return false  // Expected operational errors
        default:
            return true  // Configuration/programming errors
        }
    }

    private static func shouldCaptureOAuthAuthorizationError(code: Int) -> Bool {
        switch code {
        case OIDErrorCodeOAuthAuthorization.accessDenied.rawValue,
             OIDErrorCodeOAuthAuthorization.serverError.rawValue,
             OIDErrorCodeOAuthAuthorization.temporarilyUnavailable.rawValue:
            return false  // User action or transient issues
        default:
            return true  // Configuration errors
        }
    }

    private static func shouldCaptureOAuthTokenError(code: Int) -> Bool {
        code != OIDErrorCodeOAuthToken.invalidGrant.rawValue
    }
}

extension AuthError {
    /// Converts an AppAuth or system error to a specific AuthError type
    /// - Parameters:
    ///   - error: The error to convert
    ///   - description: Optional description for unexpected errors. Defaults to "Unhandled error"
    /// - Returns: A specific AuthError case
    static func from(_ error: any Error, description: String = "Unhandled error") -> AuthError {
        // If already AuthError, return as-is
        if let authError = error as? AuthError {
            return authError
        }

        let nsError = error as NSError

        // Check for URL errors (network issues)
        if let urlError = error as? URLError {
            return .networkError(urlError)
        }

        // Check OIDGeneralErrorDomain
        if nsError.domain == OIDGeneralErrorDomain {
            // Special case: user cancellation
            if nsError.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue {
                return .userCancelledFlow
            }
            // All other OIDGeneralErrorDomain errors
            return .oidGeneralError(code: nsError.code, underlyingError: error)
        }

        // Check OIDOAuthAuthorizationErrorDomain
        if nsError.domain == OIDOAuthAuthorizationErrorDomain {
            let errorDescription = nsError.localizedDescription
            return .oauthAuthorizationError(code: nsError.code, description: errorDescription)
        }

        // Check OIDOAuthTokenErrorDomain
        if nsError.domain == OIDOAuthTokenErrorDomain {
            let errorDescription = nsError.localizedDescription
            return .oauthTokenError(code: nsError.code, description: errorDescription)
        }

        // Check OIDHTTPErrorDomain
        if nsError.domain == OIDHTTPErrorDomain {
            return .unexpectedResponse(nsError.code)
        }

        // Fallback to generic unexpected error with provided description
        return .unexpectedError(description: description, underlyingError: error)
    }
}
