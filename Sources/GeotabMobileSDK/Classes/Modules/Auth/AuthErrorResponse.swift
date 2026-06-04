import Foundation

struct AuthErrorResponse: Codable {
    let code: String
    let message: String
    let recoverable: Bool
    let requiresReauthentication: Bool?
    let underlyingError: String?
    let shouldRedirectToLogin: Bool

    init(from authError: AuthError) {
        self.code = authError.errorCode
        self.message = authError.fallbackErrorMessage
        self.recoverable = authError.isRecoverable

        switch authError {
        case .tokenRefreshFailed(_, let error, let requiresReauth, let shouldRedirectToLogin):
            self.requiresReauthentication = requiresReauth
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .failedToSaveAuthState(_, let error, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .usernameMismatch(_, _, _, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            self.underlyingError = nil
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .noAccessTokenFoundError(_, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            self.underlyingError = nil
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .unexpectedError(let description, let error, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            if let error {
                self.underlyingError = "\(description): \(error.localizedDescription)"
            } else {
                self.underlyingError = description
            }
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .networkError(let error, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .unexpectedResponse(let statusCode, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            self.underlyingError = "HTTP \(statusCode)"
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .oidGeneralError(_, let error, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .oauthAuthorizationError(let code, let description, let shouldRedirectToLogin):
            self.requiresReauthentication = nil
            self.underlyingError = "Code \(code): \(description)"
            self.shouldRedirectToLogin = shouldRedirectToLogin

        case .oauthTokenError(let code, let description, let shouldRedirectToLogin):
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
             self.requiresReauthentication = nil
             self.underlyingError = nil
             self.shouldRedirectToLogin = shouldRedirect
        }
    }
}
