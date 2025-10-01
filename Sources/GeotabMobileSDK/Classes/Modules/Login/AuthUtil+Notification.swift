import AppAuth
import Foundation

/// :nodoc:
extension Notification.Name {
    static let newAuthState = Notification.Name("GeotabMobileSDKNewAuthState")
}

extension AuthUtil {
    static let authStateKey = "authState"
    static let userKey = "user"
    func notify(user: String, authState: OIDAuthState) {
        NotificationCenter.default.post(name: .newAuthState,
                                        object: nil,
                                        userInfo: [
                                            AuthUtil.userKey: user,
                                            AuthUtil.authStateKey: authState
                                        ])
    }
}
