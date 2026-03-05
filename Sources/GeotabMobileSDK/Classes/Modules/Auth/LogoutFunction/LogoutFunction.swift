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
    private let viewPresenterProvider: any ViewPresenterProviding

    init(module: Module, authUtil: any AuthUtil = DefaultAuthUtil(), viewPresenterProvider: any ViewPresenterProviding = DefaultViewPresenterProvider()) {
        self.authUtil = authUtil
        self.viewPresenterProvider = viewPresenterProvider
        super.init(module: module, name: LogoutFunction.functionName)
    }
    
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String,  any Error>) -> Void) {
        
        var username = ""

        Task { [weak self] in
            guard let self else { return }

            
            do {
                let argument: LogoutArgument = try validateAndDecodeAuthArgument(argument: argument)
                username = argument.username.trimmedLowercase

                guard !username.isEmpty else {
                    throw AuthError.moduleFunctionArgumentError(ModuleFunctionArgumentTypeError.userNameRequired.localizedDescription)
                }

                let presentingVC = try await viewPresenterProvider.viewPresenter()
                try await authUtil.logOut(userName: username, presentingViewController: presentingVC)
                jsCallback(.success("undefined"))
            } catch {
                let authError = AuthError.from(error, description: "Logout failed with unexpected error")

                // Always log the error for debugging (unless it's noAccessTokenFoundError which is common)
                if case AuthError.noAccessTokenFoundError = authError {
                    self.$logger.warn("No access token found during logout for user \(username)")
                } else {
                    self.$logger.error("Logout failed for user \(username): \(authError)")
                }

                // Capture unexpected errors in Sentry
                if AuthError.shouldBeCaptured(authError) {
                    await self.logger.authFailure(
                        username: username,
                        flowType: .logout,
                        error: authError
                    )
                }
                jsCallback(.failure(authError))
            }
        }
    }
}

