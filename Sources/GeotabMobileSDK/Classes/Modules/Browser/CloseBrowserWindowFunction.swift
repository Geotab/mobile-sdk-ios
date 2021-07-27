// Copyright © 2021 Geotab Inc. All rights reserved.

import SafariServices

class CloseBrowserWindowFunction: ModuleFunction {
    private let module: BrowserModule
    init(module: BrowserModule) {
        self.module = module
        super.init(module: module, name: "closeBrowserWindow")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        DispatchQueue.main.async{
            
            if(self.module.inAppBrowserVC != nil){

                if(self.module.inAppBrowserVC!.isBeingDismissed){
                    self.module.inAppBrowserVC = nil
                    jsCallback(Result.success("undefined"))
                    return
                }
                
                self.module.inAppBrowserVC?.dismiss(animated: true)
                self.module.inAppBrowserVC = nil
                
            }
            
            jsCallback(Result.success("undefined"))
        }
    }
}
