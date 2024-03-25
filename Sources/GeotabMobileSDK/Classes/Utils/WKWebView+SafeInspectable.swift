import WebKit

internal extension WKWebView {
    func safeSetInspectable() {
        #if DEBUG
        if #available(iOS 16.4, *) {
            // https://webkit.org/blog/13936/enabling-the-inspection-of-web-content-in-apps/
            // webView.isInspectable is available in Xcode 14.3, but Fortify is
            // locked at 14.1. So, call it using ObjC selectors.
            if responds(to: Selector(("setInspectable:"))) {
                perform(Selector(("setInspectable:")), with: true)
            }
        }
        #endif
    }
}
