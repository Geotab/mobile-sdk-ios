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
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: LoginRequiredFunctionArgument.self) else { return }
            
            self.module.loginRequiredCallback?(arg.status, arg.errorMessage)
            jsCallback(Result.success("undefined"))
        }
    }
}
