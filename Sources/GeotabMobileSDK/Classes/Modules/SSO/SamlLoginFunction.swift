import UIKit

struct SamlLoginFunctionArgument: Codable {
    let samlLoginUrl: String
}

class SamlLoginFunction: ModuleFunction {
    private static let functionName = "samlLogin"
    private var isMeDismissingAnonymousVC = false
    private weak var viewPresenter: ViewPresenter?
    private var samlLoginQueue: [SamlLoginViewController] = []
    
    init(module: SsoModule, viewPresenter: ViewPresenter) {
        self.viewPresenter = viewPresenter
        super.init(module: module, name: Self.functionName)
    }
    
    func presentLastCancellAll() {
        guard samlLoginQueue.count > 0 else {
            return
        }
        while samlLoginQueue.count > 1 {
            let vc = samlLoginQueue.removeFirst()
            vc.jsCallback?(Result.failure(GeotabDriveErrors.SamlLoginError(error: "Terminated 1")))
        }
        let vc = samlLoginQueue.removeFirst()
        presentSamlLoginViewController(vc)
    }
    
    func cancelAllSamlLogin() {
        while samlLoginQueue.count > 0 {
            let vc = samlLoginQueue.removeFirst()
            vc.jsCallback?(Result.failure(GeotabDriveErrors.SamlLoginError(error: "Terminated 2")))
        }
    }
    
    func presentSamlLoginViewController(_ vc: SamlLoginViewController) {
        let nc = SamlLoginNavigationController(rootViewController: vc)
        viewPresenter?.present(nc, animated: true) {
            // newer call queued. dismiss myself show the latest
            guard self.samlLoginQueue.count > 0 else {
                return
            }
            vc.dismissWith(error: GeotabDriveErrors.SamlLoginError(error: "Terminated 3"))
        }
    }
    
    func addToSamlLoginQueue(samlLoginUrl: String, jsCallback: @escaping (Result<String, Error>) -> Void) {
        let vc = UIStoryboard(name: "SamlLogin", bundle: Bundle.module).instantiateViewController(withIdentifier: "samlLogin") as! SamlLoginViewController
        vc.samlLoginUrl = samlLoginUrl
        vc.jsCallback = jsCallback
        vc.onDimissal = { [weak self] result in
            vc.jsCallback?(result)
            self?.presentLastCancellAll()
        }
        samlLoginQueue.append(vc)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: SamlLoginFunctionArgument.self) else { return }
            
            guard URL(string: arg.samlLoginUrl) != nil else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            if let presentedViewController = self.viewPresenter?.presentedViewController {
                self.addToSamlLoginQueue(samlLoginUrl: arg.samlLoginUrl, jsCallback: jsCallback)
                if let nc = self.viewPresenter?.presentedViewController as? SamlLoginNavigationController, let vc = nc.topViewController as? SamlLoginViewController {
                    guard presentedViewController.isBeingPresented == false &&
                        presentedViewController.isBeingDismissed == false else {
                        return
                    }
                    vc.dismissWith(error: GeotabDriveErrors.SamlLoginError(error: "Terminated 4"))
                } else {
                    guard presentedViewController.isBeingPresented == false &&
                            presentedViewController.isBeingDismissed == false else {
                        if self.isMeDismissingAnonymousVC == false {
                            self.cancelAllSamlLogin()
                        }
                        return
                    }
                    self.isMeDismissingAnonymousVC = true
                    self.viewPresenter?.presentedViewController?.dismiss(animated: true) {
                        self.isMeDismissingAnonymousVC = false
                        self.presentLastCancellAll()
                    }
                }
                return
            }
            
            let vc = UIStoryboard(name: "SamlLogin", bundle: Bundle.module).instantiateViewController(withIdentifier: "samlLogin") as! SamlLoginViewController
            vc.jsCallback = jsCallback
            vc.samlLoginUrl = arg.samlLoginUrl
            vc.onDimissal = { result in
                vc.jsCallback?(result)
                self.presentLastCancellAll()
            }
            
            self.presentSamlLoginViewController(vc)
        }
    }
}

class SamlLoginNavigationController: UINavigationController {
    
}
