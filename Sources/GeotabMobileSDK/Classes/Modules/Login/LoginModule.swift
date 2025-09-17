import Foundation

class LoginModule: Module {
    
    static let moduleName = "login"
    
    init() {
        super.init(name: LoginModule.moduleName)
        functions.append(LoginStartFunction(module: self))
        functions.append(GetAuthTokenFunction(module: self))
    }
}
