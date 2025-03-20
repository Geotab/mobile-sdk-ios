import WebKit

extension WKWebView {
    
    static func create(userContentControllerDelegate: UserContentControllerDelegate,
                       navigationDelegate: NavigationDelegate,
                       uiDelegate: UIDelegate,
                       useAppBoundDomains: Bool,
                       userAgentTokens: String? = nil) -> WKWebView {
        
        let webviewConfig = WKWebViewConfiguration()
        
        webviewConfig.processPool = WKProcessPool()
        
        webviewConfig.limitsNavigationsToAppBoundDomains = useAppBoundDomains
        
        webviewConfig.mediaTypesRequiringUserActionForPlayback = []

        webviewConfig.allowsInlineMediaPlayback = true
        webviewConfig.suppressesIncrementalRendering = false
        webviewConfig.allowsAirPlayForMediaPlayback = true
        
        let device = DeviceModule.device
        var userAgent = "MobileSDK/\(MobileSdkConfig.sdkVersion) \(device.appName)/\(device.version)"
        if let userAgentTokens {
            userAgent += " \(userAgentTokens)"
        }
        webviewConfig.applicationNameForUserAgent = userAgent

        webviewConfig.userContentController = userContentControllerDelegate.contentController

        // using `frame: .zero` causes the error: [ViewportSizing] maximumViewportInset cannot be larger than frame
        let webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1),
                                configuration: webviewConfig)
        webView.allowsLinkPreview = false
        webView.navigationDelegate = navigationDelegate
        webView.uiDelegate = uiDelegate
        
        webView.safeSetInspectable()
        
        return webView
    }
}
