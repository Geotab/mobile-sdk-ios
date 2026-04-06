import Foundation

struct AuthErrorResponse: Codable {
    let code: String
    let message: String
    let recoverable: Bool
    let requiresReauthentication: Bool?
    let username: String?
    let underlyingError: String?
    let shouldRedirectToLogin: Bool

    init(from authError: AuthError) {
        self.code = authError.errorCode
        self.message = authError.fallbackErrorMessage
        self.recoverable = authError.isRecoverable

        switch authError {
        case .tokenRefreshFailed(let username, let error, let requiresReauth, let shouldRedirectToLogin):
            self.username = username
            self.requiresReauthentication = requiresReauth
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .failedToSaveAuthState(let username, let error, let shouldRedirectToLogin):
            self.username = username
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .usernameMismatch(let expected, let actual, _, let shouldRedirectToLogin):
            self.username = expected
            self.requiresReauthentication = nil
            self.underlyingError = "Actual username: \(actual)"
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .noAccessTokenFoundError(let username, let shouldRedirectToLogin):
            self.username = username
            self.requiresReauthentication = nil
            self.underlyingError = nil
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .unexpectedError(let description, let error, let shouldRedirectToLogin):
            self.username = nil
            self.requiresReauthentication = nil
            if let error {
                self.underlyingError = "\(description): \(error.localizedDescription)"
            } else {
                self.underlyingError = description
            }
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .networkError(let error, let shouldRedirectToLogin):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .unexpectedResponse(let statusCode, let shouldRedirectToLogin):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = "HTTP \(statusCode)"
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .oidGeneralError(_, let error, let shouldRedirectToLogin):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .oauthAuthorizationError(let code, let description, let shouldRedirectToLogin):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = "Code \(code): \(description)"
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .oauthTokenError(let code, let description, let shouldRedirectToLogin):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = "Code \(code): \(description)"
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .revokeTokenFailed(let shouldRedirect),
              .userCancelledFlow(let shouldRedirect),
              .noDataFoundError(let shouldRedirect),
              .parseFailedForAuthState(let shouldRedirect),
              .missingAuthData(let shouldRedirect),
              .noExternalUserAgent(let shouldRedirect),
              .moduleFunctionArgumentError(_, let shouldRedirect):
             self.username = nil
             self.requiresReauthentication = nil
             self.underlyingError = nil
             self.shouldRedirectToLogin = shouldRedirect
        }
    }
}
