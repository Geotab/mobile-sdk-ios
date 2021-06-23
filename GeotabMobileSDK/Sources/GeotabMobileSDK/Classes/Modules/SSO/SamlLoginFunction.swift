//
//  SamlLoginFunction.swift
//  
//
//  Created by Yunfeng Liu on 2021-06-07.
//

import UIKit


struct SamlLoginFunctionArgument: Codable {
    let samlLoginUrl: String
}

class SamlLoginFunction: ModuleFunction {
    private var isMeDismissingAnonymousVC = false
    let module: SsoModule
    var samlLoginQueue: [SamlLoginViewController] = []
    init(module: SsoModule, name: String) {
        self.module = module
        super.init(module: module, name: name)
    }
    
    func presentLastCancellAll() {
        guard samlLoginQueue.count > 0 else {
            return
        }
        while samlLoginQueue.count > 1 {
            let vc = samlLoginQueue.removeFirst();
            vc.jsCallback?(Result.failure(GeotabDriveErrors.SamlLoginError(error: "Terminated 1")))
        }
        let vc = samlLoginQueue.removeFirst();
        presentSamlLoginViewController(vc)
    }
    
    func cancelAllSamlLogin() {
        while samlLoginQueue.count > 0 {
            let vc = samlLoginQueue.removeFirst();
            vc.jsCallback?(Result.failure(GeotabDriveErrors.SamlLoginError(error: "Terminated 2")))
        }
    }
    
    func presentSamlLoginViewController(_ vc: SamlLoginViewController) {
        let nc = SamlLoginNavigationController(rootViewController: vc)
        self.module.viewPresenter.present(nc, animated: true) {
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
        vc.onDimissal = { result in
            vc.jsCallback?(result)
            self.presentLastCancellAll()
        }
        samlLoginQueue.append(vc)
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        DispatchQueue.main.async{
            
            guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let argData = try? JSONSerialization.data(withJSONObject: argument!) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            guard let arg = try? JSONDecoder().decode(SamlLoginFunctionArgument.self, from: argData) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            guard URL(string: arg.samlLoginUrl) != nil else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            if let presentedViewController = self.module.viewPresenter.presentedViewController {
                self.addToSamlLoginQueue(samlLoginUrl: arg.samlLoginUrl, jsCallback: jsCallback)
                if let nc = self.module.viewPresenter.presentedViewController as? SamlLoginNavigationController, let vc = nc.topViewController as? SamlLoginViewController {
                    guard presentedViewController.isBeingPresented == false &&
                        presentedViewController.isBeingDismissed == false else{
                        return
                    }
                    vc.dismissWith(error: GeotabDriveErrors.SamlLoginError(error: "Terminated 4"))
                } else {
                    guard presentedViewController.isBeingPresented == false &&
                            presentedViewController.isBeingDismissed == false else{
                        if self.isMeDismissingAnonymousVC == false {
                            self.cancelAllSamlLogin();
                        }
                        return
                    }
                    self.isMeDismissingAnonymousVC = true
                    self.module.viewPresenter.presentedViewController?.dismiss(animated: true) {
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
