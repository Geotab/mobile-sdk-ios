public import Foundation
public import UIKit

/// :nodoc:
public protocol AppBundle {
    var bundleIdentifier: String? { get }
    var displayName: String? { get }
    var version: String? { get }
    var buildNumber: String? { get }
    
    func object(forInfoDictionaryKey key: String) -> Any?
}

/// :nodoc:
public protocol CurrentDevice {
    var modelName: String { get }
}

/// :nodoc:
public protocol AppStorage {
    func string(forKey defaultName: String) -> String?
    func set(_ value: Any?, forKey defaultName: String)
}

/// :nodoc:
public class Device {
    public let model: String
    public let platform: String
    public let uuid: String
    public let appId: String
    public let appName: String
    public let version: String
    public let sdkVersion: String
    public let manufacturer: String
    
    public init(bundle: any AppBundle = Bundle.main,
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
    public var displayName: String? { object(forInfoDictionaryKey: "CFBundleDisplayName") as? String }
    public var version: String? { return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String }
    public var buildNumber: String? { object(forInfoDictionaryKey: "CFBundleVersion") as? String }
}

extension UIDevice: CurrentDevice {
    public var modelName: String {
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
