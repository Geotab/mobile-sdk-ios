import Foundation

struct GetAuthTokenArgument: Codable {
    let username: String?
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
        
        guard let argument = validateAndDecodeJSONObject(argument: argument,
                                                         jsCallback: jsCallback,
                                                         decodeType: GetAuthTokenArgument.self) else { return }
        
        guard let username = argument.username, !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: "Username is required")))
            return
        } 
        
        Task { [weak self] in
            guard let self else { return }

            do {
                let tokenResponse = try await authUtil.getValidAccessToken(username: username)
                guard let jsonString = toJson(tokenResponse) else {
                    jsCallback(.failure(AuthError.unexpectedError(description: "Failed to serialize token response", underlyingError: nil)))
                    return
                }
               jsCallback(.success(jsonString))
            } catch {
                let authError = (error as? AuthError) ?? AuthError.unexpectedError(description: "Get token failed with unexpected error", underlyingError: error)
                if case AuthError.noAccessTokenFoundError = authError  {
                    // expected
                } else if !AuthError.isExpectedError(authError) {
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
