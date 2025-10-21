import Foundation

public struct MobileSdkOptions {
    public static let `default` = MobileSdkOptions()

    /// :nodoc:
    public let useAppBoundDomains: Bool
    /// :nodoc:
    public let shouldPromptForPermissions: Bool
    /// :nodoc:
    public let makeWebViewInspectable: Bool
    /// :nodoc:
    public let userAgentTokens: String?
    /// :nodoc:
    public let includeAppAuthModules: Bool
    /// :nodoc:
    public init(useAppBoundDomains: Bool = true,
                shouldPromptForPermissions: Bool = true,
                makeWebViewInspectable: Bool = false,
                userAgentTokens: String? = nil,
                includeAppAuthModules: Bool = false) {
        self.useAppBoundDomains = useAppBoundDomains
        self.shouldPromptForPermissions = shouldPromptForPermissions
        self.makeWebViewInspectable = makeWebViewInspectable
        self.userAgentTokens = userAgentTokens
        self.includeAppAuthModules = includeAppAuthModules
    }
}
