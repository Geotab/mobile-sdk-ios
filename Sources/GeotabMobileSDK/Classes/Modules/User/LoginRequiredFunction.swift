import Foundation

protocol LoginRequiredNotifying {
    func loginRequired(arg: LoginRequiredFunctionArgument)
}

struct LoginRequiredFunctionArgument: Codable {
    let status: String
    let errorMessage: String?
}

class LoginRequiredFunction: ModuleFunction {
    private let module: UserModule
    private let loginRequiredNotifier: LoginRequiredNotifying
    init(module: UserModule,
         loginRequiredNotifier: LoginRequiredNotifying = DefaulLoginRequiredNotifier()) {
        self.module = module
        self.loginRequiredNotifier = loginRequiredNotifier
        super.init(module: module, name: "loginRequired")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: LoginRequiredFunctionArgument.self) else { return }
            
            self.module.loginRequiredCallback?(arg.status, arg.errorMessage)
            loginRequiredNotifier.loginRequired(arg: arg)
            jsCallback(Result.success("undefined"))
        }
    }
}

public extension Notification.Name {
    static let loginRequired = Notification.Name("GeotabDriveSDK.loginRequired")
}

private class DefaulLoginRequiredNotifier: LoginRequiredNotifying {
    func loginRequired(arg: LoginRequiredFunctionArgument) {
        NotificationCenter.default.post(name: .loginRequired, object: arg)
    }
}
