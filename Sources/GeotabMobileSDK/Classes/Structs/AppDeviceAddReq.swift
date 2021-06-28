//
//  File.swift
//  
//
//  Created by Yunfeng Liu on 2021-06-03.
//

import Foundation

struct AppDeviceAddReq: Codable {
    let appUUID: String
    let appId: String
    let platform: String
    let model: String
    let notificationToken: String
    let expireAfterDays: Int
    init(notificationToken: String, expireAfterDays: Int) {
        appUUID = DeviceModule.device.uuid
        appId = DeviceModule.device.appId
        platform = DeviceModule.device.platform
        model = DeviceModule.device.model
        self.notificationToken = notificationToken
        self.expireAfterDays = expireAfterDays
    }
}
