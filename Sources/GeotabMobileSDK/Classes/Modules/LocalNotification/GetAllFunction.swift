

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
        center.getDeliveredNotifications{ nts in
            notifications += nts.map({ nt -> NativeNotify? in
                self.transformToNativeNotify(content: nt.request.content)
            }).filter { $0 != nil } as! [NativeNotify]
            
            center.getPendingNotificationRequests { reqs in
                notifications += reqs.map({ req -> NativeNotify? in
                    self.transformToNativeNotify(content: req.content)
                }).filter { $0 != nil } as! [NativeNotify]
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
