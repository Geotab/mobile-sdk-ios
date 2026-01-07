import Foundation

struct LoginArgument: Codable {
    let clientId: String
    let discoveryUri: String
    let username: String
    let ephemeralSession: Bool?
}

class LoginFunction: ModuleFunction {

    private static let functionName = "login"
    private let authUtil: any AuthUtil
    private let bundle: any AppBundle
    private static let redirectSchemeKey = "geotab_login_redirect_scheme"

    @TaggedLogger("LoginFunction")
    private var logger

    init(module: Module, util: any AuthUtil = DefaultAuthUtil(),
         bundle: any AppBundle = Bundle.main) {
        self.bundle = bundle
        self.authUtil = util
        super.init(module: module, name: LoginFunction.functionName)}
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        
        guard let argument = validateAndDecodeJSONObject(argument: argument,
                                                         jsCallback: jsCallback,
                                                         decodeType: LoginArgument.self) else { return }
        
        guard !argument.clientId.isEmpty, !argument.discoveryUri.isEmpty else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        let username = argument.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: "Username is required")))
            return
        }
        
        guard let discoveryURL = URL(string: argument.discoveryUri), discoveryURL.scheme?.lowercased() == "https" else {
            jsCallback(.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: AuthError.invalidURL.localizedDescription)))
            return
        }
        
        guard let redirectScheme = getRedirectScheme(bundle: bundle), let redirectUriURL = URL(string: redirectScheme)  else {
            jsCallback(.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: AuthError.invalidRedirectScheme(LoginFunction.redirectSchemeKey).localizedDescription)))
            return
        }
        
        Task { [weak self] in
            guard let self else { return }

            do {
                let tokens = try await authUtil.login(clientId: argument.clientId,
                                                      discoveryUri: discoveryURL,
                                                      username: username,
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
                self.$logger.error("Login failed for user \(username): \(authError)")

                // Capture unexpected errors in Sentry
                if AuthError.shouldBeCaptured(authError) {
                    await self.logger.authFailure(
                        username: username,
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
        guard let redirectScheme = bundle?.object(forInfoDictionaryKey: LoginFunction.redirectSchemeKey) as? String else {  return nil }
        return redirectScheme
    }
}
