import Foundation

struct GetAuthTokenArgument: Codable {
    let username: String
}

class GetTokenFunction: ModuleFunction {

    private static let functionName = "getToken"
    private let authUtil: any AuthUtil

    @TaggedLogger("GetTokenFunction")
    private var logger

    init(module: Module, util: any AuthUtil = DefaultAuthUtil()) {
        authUtil = util
        super.init(module: module, name: GetTokenFunction.functionName)}
    
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {

        var username = ""
        
        Task { [weak self] in
            guard let self else { return }

            do {
                let argument: GetAuthTokenArgument = try validateAndDecodeAuthArgument(argument: argument)
                username = argument.username.trimmedLowercase

                guard !username.isEmpty else {
                    throw AuthError.moduleFunctionArgumentError(ModuleFunctionArgumentTypeError.userNameRequired.localizedDescription)
                }

                let tokenResponse = try await authUtil.getValidAccessToken(username: username)
                guard let jsonString = toJson(tokenResponse) else {
                    throw AuthError.unexpectedError(description: "Failed to serialize token response", underlyingError: nil)
                }
               jsCallback(.success(jsonString))
            } catch {
                let authError = AuthError.from(error, description: "Get token failed with unexpected error")

                // Always log the error for debugging (unless it's noAccessTokenFoundError which is common)
                if case AuthError.noAccessTokenFoundError = authError {
                    self.$logger.warn("No access token found for user \(username)")
                } else {
                    self.$logger.error("Get token failed for user \(username): \(authError)")
                }

                // Capture unexpected errors in Sentry
                if AuthError.shouldBeCaptured(authError) {
                    await self.logger.authFailure(
                        username: username,
                        flowType: .tokenRefresh,
                        error: authError
                    )
                }
                jsCallback(.failure(authError))
            }
        }
    }
}
