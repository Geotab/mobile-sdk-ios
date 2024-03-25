import UIKit

class RequestPermissionFunction: ModuleFunction {
    private let module: LocalNotificationModule
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: "requestPermission")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard module.options.shouldPromptForPermissions else {
            jsCallback(Result.success("true"))
            return
        }

        module.notificationAdapter.requestAuth(options: [.alert, .sound, .badge]) { granted in
            if granted != true {
                jsCallback(Result.success("false"))
            } else {
                jsCallback(Result.success("true"))
            }
        }        
    }
}
