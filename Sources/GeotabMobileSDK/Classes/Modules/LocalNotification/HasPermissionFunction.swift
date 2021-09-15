

import UIKit

class HasPermissionFunction: ModuleFunction {
    private let module: LocalNotificationModule
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: "hasPermission")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                jsCallback(Result.success("false"))
            } else {
                jsCallback(Result.success("true"))
            }
        }
        
    }
}
