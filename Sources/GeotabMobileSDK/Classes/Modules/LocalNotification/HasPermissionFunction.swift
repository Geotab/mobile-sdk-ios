import UIKit

class HasPermissionFunction: ModuleFunction {
    private static let functionName: String = "hasPermission"
    private weak var module: LocalNotificationModule?
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        module?.notificationAdapter?.isAuthorized {
            jsCallback(Result.success(String($0)))
        }
    }
}
