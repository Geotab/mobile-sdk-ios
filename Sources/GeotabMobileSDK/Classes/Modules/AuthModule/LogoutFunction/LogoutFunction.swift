import Foundation
import UIKit

struct LogoutArgument: Codable {
    let username: String
}

class LogoutFunction: ModuleFunction {
    
    @TaggedLogger("LogoutFunction")
    var logger
    
    private static let functionName = "logout"
    private let authUtil: any AuthUtilityConfigurator
    
    init(module: AuthModule, authUtil: any AuthUtilityConfigurator = AuthUtil()) {
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
        
        authUtil.logOut(userName: argument.username, presentingViewController: presentingVC) { result in
            switch result {
            case .success(let resultString):
                guard let jsonString = toJson(resultString) else {
                    self.$logger.error("Failed to encode result to JSON string \(resultString)")
                    jsCallback(.failure(GeotabDriveErrors.AuthFailedError(error: "Failed to encode result to JSON string")))
                    return
                }
                jsCallback(Result.success(jsonString))
            case .failure(let error):
                jsCallback(.failure(GeotabDriveErrors.AuthFailedError(error: error.localizedDescription)))
            }
        }
    }
}

