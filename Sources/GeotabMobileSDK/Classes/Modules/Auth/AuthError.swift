import Foundation
import AppAuth

enum AuthError: LocalizedError, JsonSerializableError, Equatable {
    case unexpectedError(description: String, underlyingError: (any Error)?, shouldRedirectToLogin: Bool = false)
    case noDataFoundError(shouldRedirectToLogin: Bool = false)
    case failedToSaveAuthState(username: String, underlyingError: any Error, shouldRedirectToLogin: Bool = false)
    case usernameMismatch(expected: String, actual: String, ephemeralSession: Bool, shouldRedirectToLogin: Bool = false)
    case noAccessTokenFoundError(username: String, shouldRedirectToLogin: Bool = false)
    case parseFailedForAuthState(shouldRedirectToLogin: Bool = false)
    case tokenRefreshFailed(username: String, underlyingError: any Error, requiresReauthentication: Bool, shouldRedirectToLogin: Bool = false)
    case missingAuthData(shouldRedirectToLogin: Bool = false)
    case noExternalUserAgent(shouldRedirectToLogin: Bool = false)
    case revokeTokenFailed(shouldRedirectToLogin: Bool = false)
    case unexpectedResponse(Int, shouldRedirectToLogin: Bool = false)
    case networkError(any Error, shouldRedirectToLogin: Bool = false)
    case userCancelledFlow(shouldRedirectToLogin: Bool = false)
    case moduleFunctionArgumentError(String, shouldRedirectToLogin: Bool = false)

    // OID error domain cases (from AppAuth-iOS)
    case oidGeneralError(code: Int, underlyingError: any Error, shouldRedirectToLogin: Bool = false)
    case oauthAuthorizationError(code: Int, description: String, shouldRedirectToLogin: Bool = false)
    case oauthTokenError(code: Int, description: String, shouldRedirectToLogin: Bool = false)

    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.unexpectedError(let lhsDesc, _, let lhsRedirect), .unexpectedError(let rhsDesc, _, let rhsRedirect)):
            return lhsDesc == rhsDesc && lhsRedirect == rhsRedirect
        case (.noDataFoundError(let lhsRedirect), .noDataFoundError(let rhsRedirect)):
            return lhsRedirect == rhsRedirect
        case (.failedToSaveAuthState(let lhsUsername, _, let lhsRedirect), .failedToSaveAuthState(let rhsUsername, _, let rhsRedirect)):
            return lhsUsername == rhsUsername && lhsRedirect == rhsRedirect
        case (.usernameMismatch(let lhsExpected, let lhsActual, let lhsEphemeral, let lhsRedirect), .usernameMismatch(let rhsExpected, let rhsActual, let rhsEphemeral, let rhsRedirect)):
            return lhsExpected == rhsExpected && lhsActual == rhsActual && lhsEphemeral == rhsEphemeral && lhsRedirect == rhsRedirect
        case (.noAccessTokenFoundError(let lhsUser, let lhsRedirect), .noAccessTokenFoundError(let rhsUser, let rhsRedirect)):
            return lhsUser == rhsUser && lhsRedirect == rhsRedirect
        case (.parseFailedForAuthState(let lhsRedirect), .parseFailedForAuthState(let rhsRedirect)):
            return lhsRedirect == rhsRedirect
        case (.tokenRefreshFailed(let lhsUsername, _, let lhsRequiresReauth, let lhsRedirect),
              .tokenRefreshFailed(let rhsUsername, _, let rhsRequiresReauth, let rhsRedirect)):
            return lhsUsername == rhsUsername && lhsRequiresReauth == rhsRequiresReauth && lhsRedirect == rhsRedirect
        case (.missingAuthData(let lhsRedirect), .missingAuthData(let rhsRedirect)):
            return lhsRedirect == rhsRedirect
        case (.noExternalUserAgent(let lhsRedirect), .noExternalUserAgent(let rhsRedirect)):
            return lhsRedirect == rhsRedirect
        case (.revokeTokenFailed(let lhsRedirect), .revokeTokenFailed(let rhsRedirect)):
            return lhsRedirect == rhsRedirect
        case (.unexpectedResponse(let lhsCode, let lhsRedirect), .unexpectedResponse(let rhsCode, let rhsRedirect)):
            return lhsCode == rhsCode && lhsRedirect == rhsRedirect
        case (.networkError(_, let lhsRedirect), .networkError(_, let rhsRedirect)):
            return lhsRedirect == rhsRedirect
        case (.userCancelledFlow(let lhsRedirect), .userCancelledFlow(let rhsRedirect)):
            return lhsRedirect == rhsRedirect
        case (.oidGeneralError(let lhsCode, _, let lhsRedirect), .oidGeneralError(let rhsCode, _, let rhsRedirect)):
            return lhsCode == rhsCode && lhsRedirect == rhsRedirect
        case (.oauthAuthorizationError(let lhsCode, _, let lhsRedirect), .oauthAuthorizationError(let rhsCode, _, let rhsRedirect)):
            return lhsCode == rhsCode && lhsRedirect == rhsRedirect
        case (.oauthTokenError(let lhsCode, _, let lhsRedirect), .oauthTokenError(let rhsCode, _, let rhsRedirect)):
            return lhsCode == rhsCode && lhsRedirect == rhsRedirect
        case (.moduleFunctionArgumentError(let lhsStr, let lhsRedirect), .moduleFunctionArgumentError(let rhsStr, let rhsRedirect)):
            return lhsStr == rhsStr && lhsRedirect == rhsRedirect
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
        case .unexpectedError(let description, let underlyingError, _):
            if let underlyingError {
                return "An unexpected authentication error occurred: \(description). \(underlyingError.localizedDescription)"
            } else {
                return "An unexpected authentication error occurred: \(description)"
            }
        case .noDataFoundError:
            return "No data returned from authorization flow."
        case .failedToSaveAuthState(let username, let underlyingError, _):
            return "Failed to save auth state for user \(username): \(underlyingError.localizedDescription)"
        case .usernameMismatch(_, _, let ephemeralSession, _):
            if ephemeralSession {
                return "Username mismatch in ephemeral session - potential security issue"
            } else {
                return "Username mismatch in non-ephemeral session - Stale browser cookies from previous user"
            }
        case .noAccessTokenFoundError(let user, _):
            return "No auth token found for user \(user)"
        case .parseFailedForAuthState:
            return "Failed to unarchive auth state from Keychain data."
        case .tokenRefreshFailed(let username, let underlyingError, let requiresReauth, _):
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
        case .networkError(let error, _):
            return "Network error: \(error.localizedDescription)"
        case .unexpectedResponse(let code, _):
            return "Unexpected response code: \(code)"
        case .userCancelledFlow:
            return "Authentication flow was cancelled"
        case .oidGeneralError(let code, let underlyingError, _):
            let codeName = oidGeneralErrorName(code: code)
            return "AppAuth general error (\(codeName)): \(underlyingError.localizedDescription)"
        case .oauthAuthorizationError(let code, let description, _):
            return "OAuth authorization error (code \(code)): \(description)"
        case .oauthTokenError(let code, let description, _):
            return "OAuth token error (code \(code)): \(description)"
        case .moduleFunctionArgumentError(let error, _):
            return "ModuleFunctionArgumentError: \(error)"
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
        case .failedToSaveAuthState:
            return "FAILED_TO_SAVE_AUTH_STATE"
        case .usernameMismatch:
            return "USERNAME_MISMATCH"
        case .noAccessTokenFoundError:
            return "NO_ACCESS_TOKEN_FOUND"
        case .parseFailedForAuthState:
            return "PARSE_FAILED_FOR_AUTH_STATE"
        case .tokenRefreshFailed(_, _, let requiresReauth, _):
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
        case .moduleFunctionArgumentError:
            return "MODULE_FUNCTION_ARGUMENT_ERROR"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .tokenRefreshFailed(_, let error, _, _):
            return AuthError.isRecoverableError(error)
        case .networkError(let error, _):
            return AuthError.isRecoverableError(error)
        case .unexpectedError(_, let error, _):
            if let error = error {
                return AuthError.isRecoverableError(error)
            }
            return false
        case .unexpectedResponse(let statusCode, _):
            return statusCode >= 500 && statusCode < 600
        case .userCancelledFlow:
            return true
        case .oidGeneralError(let code, _, _):
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
            if case .unexpectedResponse(let statusCode, _) = authError {
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
        case .unexpectedResponse(let statusCode, _):
            return statusCode >= 400 && statusCode < 500

        // No access token - expected when user not logged in
        case .noAccessTokenFoundError:
            return false

        // Wrapped errors - check underlying
        case .tokenRefreshFailed(_, let underlyingError, _, _):
            return shouldBeCaptured(underlyingError)

        case .unexpectedError(_, let underlyingError, _):
            if let underlyingError {
                return shouldBeCaptured(underlyingError)
            }
            return true

        // OID error cases
        case .oidGeneralError(let code, _, _):
            return shouldCaptureOIDGeneralError(code: code)

        case .oauthAuthorizationError(let code, _, _):
            return shouldCaptureOAuthAuthorizationError(code: code)

        case .oauthTokenError(let code, _, _):
            return shouldCaptureOAuthTokenError(code: code)
            
        // Missing Values - don't capture
        case .moduleFunctionArgumentError:
            return false

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
    static func from(_ error: any Error, description: String = "Unhandled error", shouldRedirectToLogin: Bool? = nil) -> AuthError {
        let redirect = shouldRedirectToLogin ?? false

        // If already AuthError, preserve original shouldRedirectToLogin unless explicitly overridden
        if let e = error as? AuthError {
            switch e {
            case .unexpectedError(let d, let u, let r): return .unexpectedError(description: d, underlyingError: u, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .noDataFoundError(let r): return .noDataFoundError(shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .failedToSaveAuthState(let u, let e, let r): return .failedToSaveAuthState(username: u, underlyingError: e, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .usernameMismatch(let x, let a, let p, let r): return .usernameMismatch(expected: x, actual: a, ephemeralSession: p, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .noAccessTokenFoundError(let u, let r): return .noAccessTokenFoundError(username: u, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .parseFailedForAuthState(let r): return .parseFailedForAuthState(shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .tokenRefreshFailed(let u, let e, let req, let r): return .tokenRefreshFailed(username: u, underlyingError: e, requiresReauthentication: req, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .missingAuthData(let r): return .missingAuthData(shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .noExternalUserAgent(let r): return .noExternalUserAgent(shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .revokeTokenFailed(let r): return .revokeTokenFailed(shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .unexpectedResponse(let c, let r): return .unexpectedResponse(c, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .networkError(let e, let r): return .networkError(e, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .userCancelledFlow(let r): return .userCancelledFlow(shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .oidGeneralError(let c, let u, let r): return .oidGeneralError(code: c, underlyingError: u, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .oauthAuthorizationError(let c, let d, let r): return .oauthAuthorizationError(code: c, description: d, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .oauthTokenError(let c, let d, let r): return .oauthTokenError(code: c, description: d, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            case .moduleFunctionArgumentError(let s, let r): return .moduleFunctionArgumentError(s, shouldRedirectToLogin: shouldRedirectToLogin ?? r)
            }
        }

        let nsError = error as NSError

        // Check for URL errors (network issues)
        if let urlError = error as? URLError {
            return .networkError(urlError, shouldRedirectToLogin: redirect)
        }

        // Check OIDGeneralErrorDomain
        if nsError.domain == OIDGeneralErrorDomain {
            // Special case: user cancellation
            if nsError.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue {
                return .userCancelledFlow(shouldRedirectToLogin: redirect)
            }
            // All other OIDGeneralErrorDomain errors
            return .oidGeneralError(code: nsError.code, underlyingError: error, shouldRedirectToLogin: redirect)
        }

        // Check OIDOAuthAuthorizationErrorDomain
        if nsError.domain == OIDOAuthAuthorizationErrorDomain {
            let errorDescription = nsError.localizedDescription
            return .oauthAuthorizationError(code: nsError.code, description: errorDescription, shouldRedirectToLogin: redirect)
        }

        // Check OIDOAuthTokenErrorDomain
        if nsError.domain == OIDOAuthTokenErrorDomain {
            let errorDescription = nsError.localizedDescription
            return .oauthTokenError(code: nsError.code, description: errorDescription, shouldRedirectToLogin: redirect)
        }

        // Check OIDHTTPErrorDomain
        if nsError.domain == OIDHTTPErrorDomain {
            return .unexpectedResponse(nsError.code, shouldRedirectToLogin: redirect)
        }

        // Fallback to generic unexpected error with provided description
        return .unexpectedError(description: description, underlyingError: error, shouldRedirectToLogin: redirect)
    }
}

enum ModuleFunctionArgumentTypeError: Equatable, LocalizedError{
      case invalidArgument
      case userNameRequired
      case clientIdRequired
      case discoveryUriRequired
      case invalidDiscoveryUri
      case loginHintRequired
      case invalidRedirectScheme(key: String)

      var localizedDescription: String {
          switch self {
          case .userNameRequired:
              return "Username is required"
          case .clientIdRequired:
              return "Client ID is required"
          case .discoveryUriRequired:
              return "Discovery URI is required"
          case .invalidDiscoveryUri:
              return "Insecure Discovery URI. HTTPS is required"
          case .loginHintRequired:
              return "LoginHint is required"
          case .invalidRedirectScheme(let key):
              return "Login redirect scheme key \(key) not found in Info.plist"
          case .invalidArgument:
              return "Invalid argument"
          }
      }
  }

