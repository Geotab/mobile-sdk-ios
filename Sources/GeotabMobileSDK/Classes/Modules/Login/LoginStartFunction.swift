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
        super.init(module: module, name: LoginStartFunction.functionName)}
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        
        guard let argument = validateAndDecodeJSONObject(argument: argument,
                                                         jsCallback: jsCallback,
                                                         decodeType: LoginStartArgument.self) else { return }
        
        guard !argument.clientId.isEmpty, !argument.discoveryUri.isEmpty, !argument.loginHint.isEmpty else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        guard let discoveryURL = URL(string: argument.discoveryUri), discoveryURL.scheme?.lowercased() == "https" else {
            jsCallback(.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: AuthError.invalidURL.localizedDescription)))
            return
        }
        
        guard let redirectScheme = getRedirectScheme(bundle: bundle), let redirectUriURL = URL(string: redirectScheme)  else {
            jsCallback(.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: AuthError.invalidRedirectScheme(Self.redirectSchemeKey).localizedDescription)))
            return
        }
        
        Task {
            do {
                let tokens = try await authUtil.login(clientId: argument.clientId,
                                                      discoveryUri: discoveryURL,
                                                      username: argument.loginHint,
                                                      redirectUri: redirectUriURL,
                                                      ephemeralSession: argument.ephemeralSession ?? false)
                guard let response = toJson(tokens) else {
                    jsCallback(.failure(AuthError.unexpectedError(description: "Failed to serialize login response", underlyingError: nil)))
                    return
                }
                jsCallback(.success(response))
            } catch {
                let authError = AuthError.from(error, description: "Login failed with unexpected error")

                // Always log the error for debugging
                await self.$logger.error("Login failed for user \(argument.loginHint): \(authError)")

                // Capture unexpected errors in Sentry
                if AuthError.shouldBeCaptured(authError) {
                    await self.logger.authFailure(
                        username: argument.loginHint,
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
