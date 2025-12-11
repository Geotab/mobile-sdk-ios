import Foundation

class AuthModule: Module {

    static let moduleName = "auth"

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
        
        Task { [weak self] in
            await self?.authStateUpdater.updateAuthStates()
        }
    }
    
    deinit {
        authStateUpdater.stop()
    }
}

extension AuthModule: BackgroundUpdating {
    func registerForBackgroundUpdates() {
        authStateUpdater.registerForBackgroundUpdates()
    }
}
