import Foundation

extension SDKViewController {
    public static func performFirstRunCleanup() {
        AuthModule.performFirstRunCleanup()
    }
}
