import Foundation

public struct MobileSdkOptions {
    public static let `default` = MobileSdkOptions()

    /// :nodoc:
    public let useAppBoundDomains: Bool
    /// :nodoc:
    public let shouldPromptForPermissions: Bool
    /// :nodoc:
    public init(useAppBoundDomains: Bool = true,
                shouldPromptForPermissions: Bool = true) {
        self.useAppBoundDomains = useAppBoundDomains
        self.shouldPromptForPermissions = shouldPromptForPermissions
    }
}
