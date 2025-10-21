import Foundation

struct LoginArgument: Codable {
    let clientId: String
    let discoveryUri: String
    let username: String
    let ephemeralSession: Bool?
}

class LoginFunction: ModuleFunction {
    
    private static let functionName = "login"
    private let authUtil: any AuthUtilityConfigurator
    private let bundle: any AppBundle
    private static let redirectSchemeKey = "geotab_login_redirect_scheme"
   
    init(module: Module, util: any AuthUtilityConfigurator = AuthUtil(),
         bundle: any AppBundle = Bundle.main) {
        self.bundle = bundle
        self.authUtil = util
        super.init(module: module, name: LoginFunction.functionName)}
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        
        guard let argument = validateAndDecodeJSONObject(argument: argument,
                                                         jsCallback: jsCallback,
                                                         decodeType: LoginArgument.self) else { return }
        
        guard !argument.clientId.isEmpty, !argument.discoveryUri.isEmpty, !argument.username.isEmpty else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        guard let discoveryURL = URL(string: argument.discoveryUri), discoveryURL.scheme?.lowercased() == "https" else {
            jsCallback(.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: AppAuthError.invalidURL.rawValue)))
            return
        }
        
        guard let redirectScheme = getRedirectScheme(bundle: bundle), let redirectUriURL = URL(string: redirectScheme)  else {
            jsCallback(.failure(GeotabDriveErrors.ModuleFunctionArgumentErrorWithMessage(error: AppAuthError.invalidRedirectScheme.rawValue.replacingOccurrences(of: "[REPLACE]", with: LoginFunction.redirectSchemeKey))))
            return
        }
        
        authUtil.login(
            clientId: argument.clientId,
            discoveryUri: discoveryURL,
            username: argument.username,
            redirectUri: redirectUriURL,
            ephemeralSession: argument.ephemeralSession ?? false,
            loginCallback: jsCallback
        )
    }
    
    // MARK: - Get Redirect Scheme
    func getRedirectScheme(bundle: (any AppBundle)?) -> String? {
        guard let redirectScheme = bundle?.object(forInfoDictionaryKey: LoginFunction.redirectSchemeKey) as? String else {  return nil }
        return redirectScheme
    }
}
