import Foundation

public struct MobileSdkOptions {
    public static let `default` = MobileSdkOptions()

    /// :nodoc:
    public let useAppBoundDomains: Bool
    /// :nodoc:
    public let shouldPromptForPermissions: Bool
    /// :nodoc:
    public let userAgentTokens: String?
    /// :nodoc:
    public init(useAppBoundDomains: Bool = true,
                shouldPromptForPermissions: Bool = true,
                userAgentTokens: String? = nil) {
        self.useAppBoundDomains = useAppBoundDomains
        self.shouldPromptForPermissions = shouldPromptForPermissions
        self.userAgentTokens = userAgentTokens
    }
}
