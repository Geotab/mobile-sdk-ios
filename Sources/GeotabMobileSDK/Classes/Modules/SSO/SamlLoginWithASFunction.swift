import AuthenticationServices
import UIKit
import SwiftRison

enum Saml {
    struct Credentials: Codable {
        let userName: String?
        let sessionId: String?
        let database: String?
    }

    struct CredentialsWithServer: Codable {
        let server: String?
        let credentials: Credentials
    }
    
    struct LoginFunctionArgument: Codable {
        let samlLoginUrl: String
        let ephemeralSession: Bool?
    }
    
    static let scheme = "geotabdrive"
}

protocol SamlAuthenticating {
    func authenticate(url: URL, ephemeralSession: Bool, completion: @escaping (URL?, (any Error)?) -> Void)
}

class SamlLoginWithASFunction: ModuleFunction {
    
    private static let functionName: String = "samlLoginWithAS"
    private let jsonArgumentDecoder: any JsonArgumentDecoding
    private let authenticator: any SamlAuthenticating
    
    init(module: Module,
         authenticator: any SamlAuthenticating = DefaultSamlAuthenticator(),
         jsonArgumentDecoder: any JsonArgumentDecoding = JsonArgumentDecoder()) {
        self.jsonArgumentDecoder = jsonArgumentDecoder
        self.authenticator = authenticator
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        
        guard let data = jsonArgumentToData(argument),
              let arg = try? jsonArgumentDecoder.decode(Saml.LoginFunctionArgument.self, from: data) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        guard let loginUrl = URL(string: arg.samlLoginUrl) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }

        guard ["http", "https"].contains(loginUrl.scheme?.lowercased()) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }

        let useEmphemeralSession = arg.ephemeralSession ?? true        
        authenticator.authenticate(url: loginUrl,
                                   ephemeralSession: useEmphemeralSession) { [weak self] (credentialsUrl, error) in
            guard let self = self else {
                return
            }
            
            guard error == nil else {
                if let asError = error as? ASWebAuthenticationSessionError,
                   asError.errorCode == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    jsCallback(Result.failure(GeotabDriveErrors.SamlLoginCancelled))
                } else {
                    jsCallback(Result.failure(GeotabDriveErrors.SamlLoginError(error: SsoError.sessionRetrieveFailedError.rawValue)))
                }
                return
            }
            
            guard let credentialsUrl = credentialsUrl,
                  let credentials = self.credentialsFrom(url: credentialsUrl) else {
                jsCallback(Result.failure(GeotabDriveErrors.SamlLoginError(error: SsoError.sessionParseFailedError.rawValue)))
                return
            }
            
            jsCallback(Result.success(credentials))
        }
    }
    
    private func credentialsFrom(url: URL) -> String? {
        // the expected format is
        // geotabdrive://#login,(credentials:(database:\'value\',sessionId:\'value\',userName:\'value\'),server:\'value\')
        guard url.scheme == Saml.scheme else {
            return nil
        }
        
        guard let fragment = url.fragment,
              let range = fragment.range(of: "login,") else {
            return nil
        }
        
        let rison = String(fragment[range.upperBound...])
        
        guard !rison.isEmpty else {
            return nil
        }
        
        let decoder = RisonDecoder(risonString: rison)
        guard let creds = try? Saml.CredentialsWithServer(from: decoder) else {
            return nil
        }

        guard let jsonData = try? JSONEncoder().encode(creds) else {
            return nil
        }

        let jsonString = String(decoding: jsonData, as: UTF8.self)
            
        if !FeatureFlag.samlLoginJsonEscapingKillSwitch.isEnabled {
            return toJson(jsonString)
        }
        return "'\(jsonString)'"

    }
}

// MARK: - DefaultSamlAuthenticator
class DefaultSamlAuthenticator: NSObject, SamlAuthenticating, ASWebAuthenticationPresentationContextProviding {
    var session: ASWebAuthenticationSession?
    func authenticate(url: URL,
                      ephemeralSession: Bool,
                      completion: @escaping (URL?, (any Error)?) -> Void) {
        session = ASWebAuthenticationSession(url: url,
                                             callbackURLScheme: Saml.scheme,
                                             completionHandler: { [weak self] url, err in
            guard let self else {
                return
            }
            completion(url, err)
            self.session = nil}
        )
        
        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = ephemeralSession
        
        session?.start()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let window = UIApplication.shared.window {
                return window
        }
        return ASPresentationAnchor()
    }
}

// MARK: - Helper extentions
extension URL {
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}
