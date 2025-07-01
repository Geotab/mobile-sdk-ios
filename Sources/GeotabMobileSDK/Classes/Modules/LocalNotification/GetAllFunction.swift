import UIKit

class GetAllFunction: ModuleFunction {
    private static let functionName: String = "getAll"
    private weak var module: LocalNotificationModule?
    
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
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
        module?.notificationAdapter?.getDelivered { [weak self] nts in
            notifications += nts
            self?.module?.notificationAdapter?.getPendingRequests { reqs in
                notifications += reqs
                result(notifications)
            }
        }
    }
}
