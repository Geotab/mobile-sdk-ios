import Foundation
import UIKit

class Device {
    let model: String
    let platform: String
    let uuid: String
    let appId: String
    let appName: String
    let version: String
    let sdkVersion: String
    let manufacturer: String
    
    init() {
        self.platform = "iOS"
        self.manufacturer = "Apple"
        self.appId = Bundle.main.bundleIdentifier ?? ""
        
        self.appName = Bundle.main.displayName ?? ""
        self.version = Bundle.main.version ?? ""
        self.sdkVersion = DriveSdkConfig.sdkVersion
        self.model = UIDevice.current.modelName
        var uuid = UserDefaults.standard.string(forKey: "uuid")
        if uuid == nil {
            uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: "uuid")
        }
        self.uuid = uuid!
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
