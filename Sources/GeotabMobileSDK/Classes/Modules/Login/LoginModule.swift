import Foundation

class LoginModule: Module {
    
    static let moduleName = "login"
    
    let authStateUpdater: any AuthStateUpdating
    
    init(authStateUpdater: any AuthStateUpdating = AuthStateUpdater()) {
        self.authStateUpdater = authStateUpdater
        super.init(name: LoginModule.moduleName)
        functions.append(LoginStartFunction(module: self))
        functions.append(GetAuthTokenFunction(module: self))
        authStateUpdater.start()
        Task { [weak self] in
            await self?.authStateUpdater.updateAuthStates()
        }
    }
    
    deinit {
        authStateUpdater.stop()
    }
}

extension LoginModule: BackgroundUpdating {
    func registerForBackgroundUpdates() {
        authStateUpdater.registerForBackgroundUpdates()
    }
}
