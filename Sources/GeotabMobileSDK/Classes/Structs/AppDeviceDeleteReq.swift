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
