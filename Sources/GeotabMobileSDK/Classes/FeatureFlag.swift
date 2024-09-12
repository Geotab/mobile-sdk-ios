import Foundation

/// :nodoc:
public enum FeatureFlag: String, CaseIterable {
    case none = "NONE"

    public var isEnabled: Bool { UserDefaults.standard.bool(forKey: self.rawValue) }
    
    public static func set(flag: FeatureFlag, value: Bool) {
        UserDefaults.standard.setValue(value, forKey: flag.rawValue)
    }
}
