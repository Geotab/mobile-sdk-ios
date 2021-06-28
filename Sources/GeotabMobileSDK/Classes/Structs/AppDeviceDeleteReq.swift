//
//  File.swift
//  
//
//  Created by Yunfeng Liu on 2021-06-03.
//

import Foundation

struct AppDeviceDeleteReq: Codable {
    let appUUID: String
    let appId: String
    let platform: String
    init() {
        appUUID = DeviceModule.device.uuid
        appId = DeviceModule.device.appId
        platform = DeviceModule.device.platform
    }
}
