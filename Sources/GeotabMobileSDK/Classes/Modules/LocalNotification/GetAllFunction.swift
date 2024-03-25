import UIKit

class GetAllFunction: ModuleFunction {
    private let module: LocalNotificationModule
    
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: "getAll")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        getAll { result in
            guard let json = toJson(result) else {
                jsCallback(Result.success("[]"))
                return
            }
            jsCallback(Result.success(json))
        }
    }
    
    func getAll(_ result: @escaping ([NativeNotify]) -> Void) {
        var notifications: [NativeNotify] = []
        module.notificationAdapter.getDelivered { nts in
            notifications += nts
            self.module.notificationAdapter.getPendingRequests { reqs in
                notifications += reqs
                result(notifications)
            }
        }
    }
}
