import Foundation

class AuthModule: Module {
    
    static let moduleName = "auth"
    
    init() {
        super.init(name: AuthModule.moduleName)
        functions.append(LogoutFunction(module: self))
    }
}

