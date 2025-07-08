import Foundation
import UIKit

public protocol AppBundle {
    var bundleIdentifier: String? { get }
    var displayName: String? { get }
    var version: String? { get }
    var buildNumber: String? { get }
    
    func object(forInfoDictionaryKey key: String) -> Any?
}

protocol CurrentDevice {
    var modelName: String { get }
}

protocol AppStorage {
    func string(forKey defaultName: String) -> String?
    func set(_ value: Any?, forKey defaultName: String)
}

class Device {
    let model: String
    let platform: String
    let uuid: String
    let appId: String
    let appName: String
    let version: String
    let sdkVersion: String
    let manufacturer: String
    
    init(bundle: any AppBundle = Bundle.main,
         device: any CurrentDevice = UIDevice.current,
         userDefaults: any AppStorage = UserDefaults.standard) {
        
        platform = "iOS"
        manufacturer = "Apple"
        appId = bundle.bundleIdentifier ?? ""
        appName = bundle.displayName ?? ""
        sdkVersion = DriveSdkConfig.sdkVersion
        model = device.modelName

        if let version = bundle.version {
            if let buildNumber = bundle.buildNumber {
                self.version = "\(version)_\(buildNumber)"
            } else {
                self.version = version
            }
        } else {
            self.version = ""
        }

        if let uuid = userDefaults.string(forKey: "uuid") {
            self.uuid = uuid
        } else {
            self.uuid = UUID().uuidString
            userDefaults.set(self.uuid, forKey: "uuid")
        }
    }
}

extension Bundle: AppBundle {
    var displayName: String? { object(forInfoDictionaryKey: "CFBundleDisplayName") as? String }
    var version: String? { return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String }
    var buildNumber: String? { object(forInfoDictionaryKey: "CFBundleVersion") as? String }
}

extension UIDevice: CurrentDevice {
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

extension UserDefaults: AppStorage {
}
