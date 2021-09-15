

import UIKit
import UserNotifications

class LocalNotificationModule: Module {
    
    private static let DEFAULT_OPEN_ACTION_IDENTIFIER = "com.apple.UNNotificationDefaultActionIdentifier"
    
    // remember what the client is listening for
    var actionIdentifiers: [String] = []
    var actionHandler: ((Result<String, Error>) -> Void)?

    
    init() {
        super.init(name: "localNotification")
        UNUserNotificationCenter.current().delegate = self
        functions.append(HasPermissionFunction(module: self))
        functions.append(RequestPermissionFunction(module: self))
        functions.append(ScheduleFunction(module: self))
        functions.append(OnFunction(module: self))
        functions.append(OffFunction(module: self))
        functions.append(CancelFunction(module: self))
        functions.append(GetAllFunction(module: self))
    }
}

extension LocalNotificationModule: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // default actionIdentifier: com.apple.UNNotificationDefaultActionIdentifier
        fireActionEventHandler(center, actionIdentifier: response.actionIdentifier, notification: response.notification, completionHandler: completionHandler)
    }
    

    func fireActionEventHandler(_ center: UNUserNotificationCenter, actionIdentifier: String, notification: UNNotification, completionHandler: @escaping () -> Void) {
        
        let convertedActionIdentifier = actionIdentifier == LocalNotificationModule.DEFAULT_OPEN_ACTION_IDENTIFIER ? "click" : actionIdentifier
        guard let _ = actionIdentifiers.firstIndex(of: convertedActionIdentifier) else {
            completionHandler()
            return
        }
        
        guard let id = Int(notification.request.identifier) else {
            completionHandler()
            return
        }
        
        // find actionHandler
        guard let actionHandler = actionHandler else {
            completionHandler()
            return
        }
        let content = notification.request.content
        guard let nativeNotifyData = content.userInfo["nativeNotify"] as? Data else {
            completionHandler()
            return
        }
        
        guard let nativeNotify = try? JSONDecoder().decode(NativeNotify.self, from: nativeNotifyData) else {
            completionHandler()
            return
        }
        
        let nativeActionEvent = NativeActionEvent(event: convertedActionIdentifier, foreground: UIApplication.shared.applicationState == .active, notification: id, queued: false)
        let nativeActionEventResult = NativeActionEventResult(notification: nativeNotify, event: nativeActionEvent)
        guard let nativeActionEventResultJson = toJson(nativeActionEventResult) else {
            completionHandler()
            return
        }
        
        actionHandler(Result.success(nativeActionEventResultJson))
        completionHandler()

    }
}
