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
        let center = UNUserNotificationCenter.current()
        var notifications: [NativeNotify] = []
        center.getDeliveredNotifications { nts in
            notifications += nts.compactMap { self.transformToNativeNotify(content: $0.request.content) }
            center.getPendingNotificationRequests { reqs in
                notifications += reqs.compactMap { self.transformToNativeNotify(content: $0.content) }
                result(notifications)
            }
        }
    }
    
    func transformToNativeNotify(content: UNNotificationContent) -> NativeNotify? {
        guard let nativeNotifyData = content.userInfo["nativeNotify"] as? Data else {
            return nil
        }
        guard let nativeNotify = try? JSONDecoder().decode(NativeNotify.self, from: nativeNotifyData) else {
            return nil
        }
        return nativeNotify
    }
    
}
