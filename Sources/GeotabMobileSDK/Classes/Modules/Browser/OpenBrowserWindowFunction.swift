// Copyright © 2021 Geotab Inc. All rights reserved.

import SafariServices

private enum HtmlTarget: String {
    case blank = "_blank"
    case `self` = "_self"
    case parent = "_parent"
    case top = "_top"
    case iab = "iab" // "iab" (in app browser) from Drive > login.ts > let win = openExternalUrl(redirectUrlWithTarget, "iab", { enableViewportScale: true });
    case system = "_system"
}

struct OpenBrowserWindowArguments: Codable {
    let url: String
    let target: String?
    let features: String? 
}

class OpenBrowserWindowFunction: ModuleFunction {
    private let module: BrowserModule
    init(module: BrowserModule) {
        self.module = module
        super.init(module: module, name: "openBrowserWindow")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async{
            
            guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let argData = try? JSONSerialization.data(withJSONObject: argument!) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            guard let arg = try? JSONDecoder().decode(OpenBrowserWindowArguments.self, from: argData) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            guard let urlString = arg.url as String?,
                let url = URL(string: urlString),
                let targetString: String = arg.target else {
                    jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                    return
            }
            
            let target = HtmlTarget(rawValue: targetString)
            switch target {
            case .blank, .system, .none:
                UIApplication.shared.open(url)
            case .parent, .top, .`self`, .iab:
                if(self.module.inAppBrowserVC != nil){
                    self.module.inAppBrowserVC?.dismiss(animated: true)
                    self.module.inAppBrowserVC = nil
                }
                
                self.module.inAppBrowserVC = SFSafariViewController(url: url)
                self.module.viewPresenter.present(self.module.inAppBrowserVC!, animated: true, completion: nil)
             
            }
            jsCallback(Result.success("\"\(urlString)\""))
        }
    }
}
