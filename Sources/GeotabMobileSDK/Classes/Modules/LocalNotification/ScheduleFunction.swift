import Foundation
import UIKit

class ScheduleFunction: ModuleFunction {
    private static let functionName: String = "schedule"
    private weak var module: LocalNotificationModule?
    
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let nativeNotify = validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: NativeNotify.self) else { return }
        
        schedule(notification: nativeNotify) { jsCallback(Result.success("\($0)")) }
        
    }
    
    private func setNotificationCategories(notification: NativeNotify, callback: @escaping (String?) -> Void) { // returns cat id

        guard let module,
              let nativeActions = notification.actions, nativeActions.count > 0 else {
            callback(nil)
            return
        }

        let actions = nativeActions.map { UNNotificationAction(identifier: $0.id, title: $0.title, options: .foreground) }
        let id = String(notification.id)
        let category = UNNotificationCategory(identifier: id, actions: actions, intentIdentifiers: [])

        module.notificationAdapter?.getCategories { cats in
            var mcats = cats
            if let index = cats.firstIndex(where: { $0.identifier == id }) {
                mcats.remove(at: index)
            }
            mcats.insert(category)
            module.notificationAdapter?.setCategories(mcats)
            callback(id)
        }
    }
    
    public func schedule(notification: NativeNotify, jsCallback: @escaping (Bool) -> Void) {
        guard let notificationAdapter = module?.notificationAdapter else { jsCallback(false); return }
        
        setNotificationCategories(notification: notification) { catId in
            
            let content = UNMutableNotificationContent()
            if let catId = catId {
                content.categoryIdentifier = catId
            }
            content.title = notification.title ?? ""
            content.body = notification.text
            content.sound = UNNotificationSound.default
            // it's safe here, NativeNotify is Codable
            content.userInfo = ["nativeNotify": try! JSONEncoder().encode(notification)]
            content.badge = 0
            
            let request = UNNotificationRequest(identifier: String(notification.id), content: content, trigger: nil)

            notificationAdapter.addRequest(request) { error in
                if error != nil {
                    jsCallback(false)
                } else {
                    jsCallback(true)
                }
            }
        }

    }
}
