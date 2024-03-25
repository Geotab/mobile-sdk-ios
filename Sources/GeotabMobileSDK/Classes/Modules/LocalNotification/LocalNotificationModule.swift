import UIKit
import UserNotifications

protocol UserNotifcationAdapter: AnyObject {
    func setDelegate(_ delegate: UNUserNotificationCenterDelegate)
    func addRequest(_ request: UNNotificationRequest, withCompletionHandler completionHandler: @escaping ((Error?) -> Void))
    func requestAuth(options: UNAuthorizationOptions, completionHandler: @escaping (Bool) -> Void)
    func removeDelivered(withIdentifiers identifiers: [String])
    func removePendingRequests(withIdentifiers identifiers: [String])
    func getDelivered(completionHandler: @escaping ([NativeNotify]) -> Void)
    func getPendingRequests(completionHandler: @escaping ([NativeNotify]) -> Void)
    func isAuthorized(completionHandler: @escaping (Bool) -> Void)
    func getCategories(completionHandler: @escaping (Set<UNNotificationCategory>) -> Void)
    func setCategories(_ categories: Set<UNNotificationCategory>)
}
    
/// :nodoc:
class LocalNotificationModule: Module {
    static let moduleName = "localNotification"
    private static let DEFAULT_OPEN_ACTION_IDENTIFIER = "com.apple.UNNotificationDefaultActionIdentifier"
    let notificationAdapter: UserNotifcationAdapter
    let options: MobileSdkOptions
    
    // remember what the client is listening for
    var actionIdentifiers: [String] = []
    var actionHandler: ((Result<String, Error>) -> Void)?
    
    init(options: MobileSdkOptions, adapter: UserNotifcationAdapter = UNUserNotificationCenter.current()) {
        self.notificationAdapter = adapter
        self.options = options
        super.init(name: LocalNotificationModule.moduleName)
        adapter.setDelegate(self)
        functions.append(HasPermissionFunction(module: self))
        functions.append(RequestPermissionFunction(module: self))
        functions.append(ScheduleFunction(module: self))
        functions.append(OnFunction(module: self))
        functions.append(OffFunction(module: self))
        functions.append(CancelFunction(module: self))
        functions.append(GetAllFunction(module: self))
    }
}

/// :nodoc:
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
        guard actionIdentifiers.firstIndex(of: convertedActionIdentifier) != nil else {
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

extension UNUserNotificationCenter: UserNotifcationAdapter {
    func setDelegate(_ delegate: UNUserNotificationCenterDelegate) {
        self.delegate = delegate
    }
    
    func addRequest(_ request: UNNotificationRequest, withCompletionHandler completionHandler: @escaping ((Error?) -> Void)) {
        add(request, withCompletionHandler: completionHandler)
    }
    
    func requestAuth(options: UNAuthorizationOptions = [], completionHandler: @escaping (Bool) -> Void) {
        requestAuthorization(options: options) { granted, _ in
            completionHandler(granted)
        }
    }
    
    func removeDelivered(withIdentifiers identifiers: [String]) {
        removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func removePendingRequests(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func getDelivered(completionHandler: @escaping ([NativeNotify]) -> Void) {
        getDeliveredNotifications { notifications in
            completionHandler(notifications.compactMap { UNUserNotificationCenter.transformToNativeNotify(content: $0.request.content) })
        }
    }
    
    func getPendingRequests(completionHandler: @escaping ([NativeNotify]) -> Void) {
        getPendingNotificationRequests { notifications in
            completionHandler(notifications.compactMap { UNUserNotificationCenter.transformToNativeNotify(content: $0.content) })
        }
    }
    
    func isAuthorized(completionHandler: @escaping (Bool) -> Void) {
        getNotificationSettings { setting in
            completionHandler(setting.authorizationStatus == .authorized)
        }
    }
    
    func getCategories(completionHandler: @escaping (Set<UNNotificationCategory>) -> Void) {
        getNotificationCategories(completionHandler: completionHandler)
    }
    
    func setCategories(_ categories: Set<UNNotificationCategory>) {
        setNotificationCategories(categories)
    }

    static func transformToNativeNotify(content: UNNotificationContent) -> NativeNotify? {
        guard let nativeNotifyData = content.userInfo["nativeNotify"] as? Data else {
            return nil
        }
        guard let nativeNotify = try? JSONDecoder().decode(NativeNotify.self, from: nativeNotifyData) else {
            return nil
        }
        return nativeNotify
    }
}
