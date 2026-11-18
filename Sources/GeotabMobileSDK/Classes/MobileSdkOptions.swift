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
    /// Supply a provider only if the app declares NSMicrophoneUsageDescription
    /// (and NSCameraUsageDescription for combined capture).
    /// Without a provider, microphone requests use WebKit's prompt when that key exists
    /// and are denied otherwise. Origin and combined-capture usage-key checks still apply.
    /// Camera-only requests never consult this provider.
    public let mediaCaptureAccess: (any MediaCaptureAccessProviding)?
    /// :nodoc:
    public init(useAppBoundDomains: Bool = true,
                shouldPromptForPermissions: Bool = true,
                makeWebViewInspectable: Bool = false,
                userAgentTokens: String? = nil,
                mediaCaptureAccess: (any MediaCaptureAccessProviding)? = nil) {
        self.useAppBoundDomains = useAppBoundDomains
        self.shouldPromptForPermissions = shouldPromptForPermissions
        self.makeWebViewInspectable = makeWebViewInspectable
        self.userAgentTokens = userAgentTokens
        self.mediaCaptureAccess = mediaCaptureAccess
    }
}
