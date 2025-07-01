import UIKit

class RequestPermissionFunction: ModuleFunction {
    private static let functionName: String = "requestPermission"
    private weak var module: LocalNotificationModule?
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        guard let module else {
            jsCallback(Result.failure(GeotabDriveErrors.InvalidObjectError))
            return
        }
        
        guard module.options.shouldPromptForPermissions else {
            jsCallback(Result.success("true"))
            return
        }

        module.notificationAdapter?.requestAuth(options: [.alert, .sound, .badge]) { granted in
            if granted != true {
                jsCallback(Result.success("false"))
            } else {
                jsCallback(Result.success("true"))
            }
        }        
    }
}
