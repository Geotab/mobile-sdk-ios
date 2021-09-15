

import Foundation

struct LoginRequiredFunctionArgument: Codable {
    let status: String
    let errorMessage: String?
}

class LoginRequiredFunction: ModuleFunction {
    private let module: UserModule
    init(module: UserModule) {
        self.module = module
        super.init(module: module, name: "loginRequired")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async {
            guard argument != nil, let data = try? JSONSerialization.data(withJSONObject: argument!) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            guard let arg = try? JSONDecoder().decode(LoginRequiredFunctionArgument.self, from: data) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            self.module.loginRequiredCallback?(arg.status, arg.errorMessage)
            jsCallback(Result.success("undefined"))
        }
    }
}
