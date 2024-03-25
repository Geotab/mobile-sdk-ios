import UIKit

class HasPermissionFunction: ModuleFunction {
    private let module: LocalNotificationModule
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: "hasPermission")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.notificationAdapter.isAuthorized {
            jsCallback(Result.success(String($0)))
        }
    }
}
