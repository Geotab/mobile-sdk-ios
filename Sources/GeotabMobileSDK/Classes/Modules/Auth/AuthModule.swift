import Foundation
import UIKit

class AuthModule: Module {

    static let moduleName = "auth"
    private static let windowReadyDelayInNanoseconds: UInt64 = 1_000_000_000

    let authStateUpdater: any AuthStateUpdating
    let authUtil: any AuthUtil

    init(authUtil: any AuthUtil = DefaultAuthUtil()) {
        self.authStateUpdater = AuthStateUpdater(authUtil: authUtil)
        self.authUtil = authUtil

        super.init(name: AuthModule.moduleName)

        functions.append(LoginFunction(module: self, util: authUtil))
        functions.append(LogoutFunction(module: self, authUtil: authUtil))
        functions.append(GetTokenFunction(module: self, util: authUtil))

        authStateUpdater.start()

        Task { @MainActor [weak self] in
            // Allow window to become ready before auth refresh (MOB-3995)
            if UIApplication.shared.applicationState == .active {
                try? await Task.sleep(nanoseconds: Self.windowReadyDelayInNanoseconds)
                await self?.authStateUpdater.updateAuthStates()
            } else {
                for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                    try? await Task.sleep(nanoseconds: Self.windowReadyDelayInNanoseconds)
                    await self?.authStateUpdater.updateAuthStates()
                    break
                }
            }
        }
    }

    deinit {
        authStateUpdater.stop()
    }

    static func performFirstRunCleanup() {
        let keychainService = DefaultKeychainService()
        keychainService.deleteAll()
    }
}

extension AuthModule: BackgroundUpdating {
    func registerForBackgroundUpdates() {
        authStateUpdater.registerForBackgroundUpdates()
    }
}
