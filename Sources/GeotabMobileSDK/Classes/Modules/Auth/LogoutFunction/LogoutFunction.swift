import Foundation
import UIKit

struct LogoutArgument: Codable {
    let username: String
}

class LogoutFunction: ModuleFunction {
    
    @TaggedLogger("LogoutFunction")
    var logger
    
    private static let functionName = "logout"
    private let authUtil: any AuthUtil
    
    init(module: Module, authUtil: any AuthUtil = DefaultAuthUtil()) {
        self.authUtil = authUtil
        super.init(module: module, name: LogoutFunction.functionName)}
    
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String,  any Error>) -> Void) {
        
        guard let argument = validateAndDecodeJSONObject(argument: argument,
                                                         jsCallback: jsCallback,
                                                         decodeType: LogoutArgument.self) else { return }
        
        guard !argument.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: "Username is required")))
            return
        }
        
        let presentingVC = UIApplication.shared.rootViewController
        
        Task {
            do {
                try await authUtil.logOut(userName: argument.username, presentingViewController: presentingVC)
                jsCallback(Result.success("undefined"))
            } catch {
                jsCallback(.failure(GeotabDriveErrors.AuthFailedError(error: error.localizedDescription)))
            }
        }
    }
}

