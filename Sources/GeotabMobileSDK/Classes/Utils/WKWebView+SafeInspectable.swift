import WebKit

extension WKWebView {
    func safeSetInspectable() {
        if #available(iOS 16.4, *) {
            // https://webkit.org/blog/13936/enabling-the-inspection-of-web-content-in-apps/
            // Use setInspectable directly (Fortify limitation removed)
            isInspectable = true
        }
    }
}
