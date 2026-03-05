import Foundation

struct LoginStartArgument: Codable {
    let clientId: String
    let discoveryUri: String
    let loginHint: String
    let ephemeralSession: Bool?
}

class LoginStartFunction: ModuleFunction {
    
    private static let functionName = "start"
    private var authUtil: any AuthUtil
    private let bundle: any AppBundle
    private static let redirectSchemeKey = "geotab_login_redirect_scheme"

    @TaggedLogger("LoginStartFunction")
    private var logger

    init(module: LoginModule, util: any AuthUtil = DefaultAuthUtil(),
         bundle: any AppBundle = Bundle.main) {
        self.bundle = bundle
        authUtil = util
        authUtil.returnAllTokensOnLogin = true
        authUtil.skipTokenPersistence = true
        super.init(module: module, name: LoginStartFunction.functionName)}
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        
        guard let argument = validateAndDecodeJSONObject(argument: argument,
                                                         jsCallback: jsCallback,
                                                         decodeType: LoginStartArgument.self) else { return }
        let loginHint = argument.loginHint.trimmedLowercase
        
        Task {
            do {
                
                guard !argument.clientId.isEmpty else {
                    throw GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: ModuleFunctionArgumentTypeError.clientIdRequired.localizedDescription)
                }
                
                guard !argument.discoveryUri.isEmpty else {
                    throw GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: ModuleFunctionArgumentTypeError.discoveryUriRequired.localizedDescription)
                }
                
                guard !loginHint.isEmpty else {
                    throw GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: ModuleFunctionArgumentTypeError.loginHintRequired.localizedDescription)
                }
                
                guard let discoveryURL = URL(string: argument.discoveryUri), discoveryURL.scheme?.lowercased() == "https" else {
                    throw GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: ModuleFunctionArgumentTypeError.invalidDiscoveryUri.localizedDescription)
                }
                
                guard let redirectScheme = getRedirectScheme(bundle: bundle), let redirectUriURL = URL(string: redirectScheme)  else {
                    throw GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: ModuleFunctionArgumentTypeError.invalidRedirectScheme(key: LoginStartFunction.redirectSchemeKey).localizedDescription)
                }
                
     
                let tokens = try await authUtil.login(clientId: argument.clientId,
                                                      discoveryUri: discoveryURL,
                                                      username: loginHint,
                                                      redirectUri: redirectUriURL,
                                                      ephemeralSession: argument.ephemeralSession ?? false)
                guard let response = toJson(tokens) else {
                    throw AuthError.unexpectedError(description: "Failed to serialize login response", underlyingError: nil)
                }
                jsCallback(.success(response))
            } catch {
                let authError = AuthError.from(error, description: "Login failed with unexpected error")

                // Always log the error for debugging
                self.$logger.error("Login failed for user \(loginHint): \(authError)")

                // Capture unexpected errors in Sentry
                if AuthError.shouldBeCaptured(authError) {
                    await self.logger.authFailure(
                        username: loginHint,
                        flowType: .login,
                        error: authError
                    )
                }
                jsCallback(.failure(authError))
            }
        }
    }
    
    // MARK: - Get Redirect Scheme
    func getRedirectScheme(bundle: (any AppBundle)?) -> String? {
        guard let redirectScheme = bundle?.object(forInfoDictionaryKey: LoginStartFunction.redirectSchemeKey) as? String else {  return nil }
        return redirectScheme
    }
}
