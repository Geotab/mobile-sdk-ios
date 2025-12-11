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
        
        Task { [weak self] in
            guard let self else { return }

            do {
                try await authUtil.logOut(userName: argument.username, presentingViewController: presentingVC)
                jsCallback(Result.success("undefined"))
            } catch {
                let authError = (error as? AuthError) ?? AuthError.unexpectedError(description: "Logout failed with unexpected error", underlyingError: error)
                if case AuthError.noAccessTokenFoundError = authError  {
                    // expected
                } else if !AuthError.isExpectedError(authError) {
                    await self.logger.authFailure(
                        username: argument.username,
                        flowType: .logout,
                        error: authError
                    )
                }
                jsCallback(.failure(authError))
            }
        }
    }
}

