import Foundation

/// :nodoc:
public enum FeatureFlag: String, CaseIterable {
    case iosOnlySetFragmentOnDeepLinks = "DRIVE.IOS_ONLY_SET_FRAGMENT_ON_DEEP_LINKS"

    public var isEnabled: Bool { UserDefaults.standard.bool(forKey: self.rawValue) }
    
    public static func set(flag: FeatureFlag, value: Bool) {
        UserDefaults.standard.setValue(value, forKey: flag.rawValue)
    }
}
