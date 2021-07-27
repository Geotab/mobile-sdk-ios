// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation
import UIKit

class ScheduleFunction: ModuleFunction {
    private let module: LocalNotificationModule
    
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: "schedule")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }

        guard let nativeNotify = try? JSONDecoder().decode(NativeNotify.self, from: data) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        schedule(notification: nativeNotify) { jsCallback(Result.success("\($0)")) }
        
    }
    
    private func setNotificationCategories(notification: NativeNotify, callback: @escaping (String?) -> Void) { // returns cat id

        guard let nativeActions = notification.actions, nativeActions.count > 0 else {
            callback(nil)
            return
        }

        let actions = nativeActions.map { UNNotificationAction(identifier: $0.id, title: $0.title, options: .foreground) }
        let id = String(notification.id)
        let category = UNNotificationCategory(identifier: id, actions: actions, intentIdentifiers: [])

        UNUserNotificationCenter.current().getNotificationCategories { cats in
            var mcats = cats
            if let index = cats.firstIndex(where: { $0.identifier == id }) {
                mcats.remove(at: index)
            }
            mcats.insert(category)
            UNUserNotificationCenter.current().setNotificationCategories(mcats)
            callback(id)
        }
    }
    
    public func schedule(notification: NativeNotify, jsCallback: @escaping (Bool) -> Void) {
        
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

            UNUserNotificationCenter.current().add(request) {
                error in
                
                if error != nil {
                    jsCallback(false)
                } else {
                    jsCallback(true)
                }
            }
        }

    }
}
