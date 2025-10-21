import Foundation

struct GetAuthTokenArgument: Codable {
    let username: String?
}

class GetTokenFunction: ModuleFunction {
    
    private static let functionName = "getToken"
    private let authUtil: any AuthUtilityConfigurator
    
    init(module: Module, util: any AuthUtilityConfigurator = AuthUtil()) {
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
        
        authUtil.getValidAccessToken(key: username) { result in
            switch result {
            case .success(let tokenResponse):
                jsCallback(.success(tokenResponse))
            case .failure(let error):
                jsCallback(.failure(GeotabDriveErrors.AuthFailedError(error: error.localizedDescription)))
            }
        }
    }
}
