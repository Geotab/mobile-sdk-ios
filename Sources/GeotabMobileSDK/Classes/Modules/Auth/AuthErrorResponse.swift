import Foundation

struct AuthErrorResponse: Codable {
    let code: String
    let message: String
    let recoverable: Bool
    let requiresReauthentication: Bool?
    let username: String?
    let underlyingError: String?

    init(from authError: AuthError) {
        self.code = authError.errorCode
        self.message = authError.fallbackErrorMessage
        self.recoverable = authError.isRecoverable

        switch authError {
        case .tokenRefreshFailed(let username, let error, let requiresReauth):
            self.username = username
            self.requiresReauthentication = requiresReauth
            self.underlyingError = error.localizedDescription

        case .failedToSaveAuthState(let username, let error):
            self.username = username
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription

        case .usernameMismatch(let expected, let actual, _):
            self.username = expected
            self.requiresReauthentication = nil
            self.underlyingError = "Actual username: \(actual)"

        case .noAccessTokenFoundError(let username):
            self.username = username
            self.requiresReauthentication = nil
            self.underlyingError = nil

        case .unexpectedError(let description, let error):
            self.username = nil
            self.requiresReauthentication = nil
            if let error {
                self.underlyingError = "\(description): \(error.localizedDescription)"
            } else {
                self.underlyingError = description
            }

        case .networkError(let error):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription

        case .unexpectedResponse(let statusCode):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = "HTTP \(statusCode)"

        case .oidGeneralError(_, let error):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = error.localizedDescription

        case .oauthAuthorizationError(let code, let description):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = "Code \(code): \(description)"

        case .oauthTokenError(let code, let description):
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = "Code \(code): \(description)"

        default:
            self.username = nil
            self.requiresReauthentication = nil
            self.underlyingError = nil
        }
    }
}
