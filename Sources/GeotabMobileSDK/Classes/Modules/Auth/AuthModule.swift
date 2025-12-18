import Foundation

class AuthModule: Module {
    
    static let moduleName = "auth"
    
    let authStateUpdater: any AuthStateUpdating
    
    init(authStateUpdater: any AuthStateUpdating = AuthStateUpdater()) {
        self.authStateUpdater = authStateUpdater
            
        super.init(name: AuthModule.moduleName)
        
        functions.append(LoginFunction(module: self))
        functions.append(LogoutFunction(module: self))
        functions.append(GetTokenFunction(module: self))
        
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
