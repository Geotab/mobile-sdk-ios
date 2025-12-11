import Foundation
import UIKit

/// :nodoc:
enum Auth {
    
    static let loggingTag = "Auth"
    
    enum TagKey {
        static let eventCategory = "event_category"
        static let authResult = "auth_result"
        static let authFlow = "auth_flow"
        static let appState = "app_state"
    }

    enum TagValue {
        static let authAttempt = "auth_attempt"
        static let failure = "failure"
    }

    enum FlowType: String {
        case login = "login"
        case reauth = "reauth"
        case tokenRefresh = "token_refresh"
        case backgroundRefresh = "background_refresh"
        case backgroundRefreshRetry = "background_refresh_retry"
        case logout = "logout"
    }

    enum AppState {
        static let foreground = "foreground"
        static let background = "background"
        static let inactive = "inactive"
    }

    enum ContextKey: String {
        case username = "username"
        case availableBytes = "available_bytes"
        case totalBytes = "total_bytes"
        case osStatus = "os_status"
        case recoverable = "recoverable"
        case requiresReauth = "requires_reauth"
        case retryAttempt = "retry_attempt"
        case stage = "stage"
        case reason = "reason"
    }

    enum LogoutStage {
        static let tokenRevocation = "token_revocation"
        static let keychainDeletion = "keychain_deletion"
        static let endSession = "end_session"
    }
}

/// :nodoc:
extension Logging {
    func authFailure(
        username: String,
        flowType: Auth.FlowType,
        error: (any Error)?,
        additionalContext: [Auth.ContextKey: Any]? = nil
    ) async {
        let appState = await UIApplication.shared.applicationState
        let appStateString = appState == .active ? Auth.AppState.foreground :
                            (appState == .background ? Auth.AppState.background : Auth.AppState.inactive)

        let tags: [String: String] = [
            Auth.TagKey.eventCategory: Auth.TagValue.authAttempt,
            Auth.TagKey.authResult: Auth.TagValue.failure,
            Auth.TagKey.authFlow: flowType.rawValue,
            Auth.TagKey.appState: appStateString
        ]

        var context: [String: Any] = [Auth.ContextKey.username.rawValue: username]

        let fileManager = FileManager.default
        if let systemAttributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            context[Auth.ContextKey.availableBytes] = systemAttributes[.systemFreeSize] as? Int64
            context[Auth.ContextKey.totalBytes] = systemAttributes[.systemSize] as? Int64
        }

        if let keychainError = error as? KeychainError,
           case .saveFailed(let osStatus) = keychainError {
            context[Auth.ContextKey.osStatus] = Int(osStatus)
        }

        if let additionalContext {
            additionalContext.forEach { context[$0.key.rawValue] = $0.value }
        }

        event(
            level: .error,
            tag: Auth.loggingTag,
            message: "Auth attempt failed",
            error: error,
            tags: tags,
            context: context
        )
    }
}

/// Dictionary extension for convenient context key usage
extension Dictionary where Key == String {
    subscript(key: Auth.ContextKey) -> Value? {
        get { self[key.rawValue] }
        set { self[key.rawValue] = newValue }
    }
}
