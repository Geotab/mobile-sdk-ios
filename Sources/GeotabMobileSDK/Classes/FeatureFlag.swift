import Foundation

/// :nodoc:
public enum FeatureFlag: String, CaseIterable {
    case none = "NONE"
    case ignoreRequestCancellationErrorsKillSwitch = "DRIVE.IOS_IGNORE_REQUEST_CANCELLATION_EXCEPTIONS_KILL_SWITCH"
    
    public var isEnabled: Bool { UserDefaults.standard.bool(forKey: self.rawValue) }
    
    public static func set(flag: FeatureFlag, value: Bool) {
        UserDefaults.standard.setValue(value, forKey: flag.rawValue)
    }
}
