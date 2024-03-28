import Foundation
import WebKit

/// :nodoc:
class SamlLoginViewController: UIViewController {
    
    private var swipeDownDismissal = true
    
    var onDimissal: ((Result<String, Error>) -> Void)?
    var samlLoginUrl: String!
    var jsCallback: ((Result<String, Error>) -> Void)?

    @IBOutlet var webview: WKWebView!
    
    private lazy var contentController: WKUserContentController = {
        let controller = WKUserContentController()
        return controller
    }()
    
    override func viewDidLoad() {
        let device = DeviceModule.device
        let url = URL(string: samlLoginUrl)!
        webview.configuration.processPool = WKProcessPool()
        webview.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webview.configuration.allowsInlineMediaPlayback = false
        webview.configuration.allowsAirPlayForMediaPlayback = false
        webview.configuration.allowsPictureInPictureMediaPlayback = false
        webview.configuration.suppressesIncrementalRendering = false
        
        webview.configuration.applicationNameForUserAgent = "MobileSDK/\(MobileSdkConfig.sdkVersion) \(device.appName)/\(device.version)"
        
        webview.navigationDelegate = self
        
        webview.evaluateJavaScript("navigator.userAgent") { ua, _  in
            let defaultUA = ua ?? ""
            self.webview.customUserAgent = "\(defaultUA) MobileSDK/\(MobileSdkConfig.sdkVersion) \(device.appName)/\(device.version)"
            self.webview.load(URLRequest(url: url))
        }
        
        navigationItem.title = url.host
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if onDimissal != nil && swipeDownDismissal {
            onDimissal?(Result.failure(GeotabDriveErrors.SamlLoginCancelled))
            onDimissal = nil
        }
    }
    
    @IBAction func cancel() {
        dismissWith(error: GeotabDriveErrors.SamlLoginCancelled)
    }
    
    @IBAction func refresh() {
        guard webview.url != nil else {
            // safe with !, presenter will set the URL.
            guard let origUrl = URL(string: samlLoginUrl) else {
                return
            }
            webview.load(URLRequest(url: origUrl))
            return
        }
        webview.reload()
    }
    
    func dismissWith(error: GeotabDriveErrors) {
        swipeDownDismissal = false
        guard isBeingDismissed == false else {
            return
        }
        dismiss(animated: true) {
            self.onDimissal?(Result.failure(error))
            self.onDimissal = nil
        }
        
    }
    
    func dismissWith(result: String) {
        swipeDownDismissal = false
        guard isBeingDismissed == false else {
            return
        }
        dismiss(animated: true) {
            self.onDimissal?(Result.success(result))
            self.onDimissal = nil
        }
        
    }
    
}

/// :nodoc:
extension SamlLoginViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.request.url?.absoluteString.lowercased().hasPrefix("http") == true else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // Uncomment this method to allow testing against localhost and other self signed https
    //    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    //        let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
    //        completionHandler(.useCredential, cred)
    //    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        dismissWith(error: GeotabDriveErrors.SamlLoginError(error: "Network error"))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webview.url, let host = url.host else {
            return
        }
        navigationItem.title = host
        guard url.path.lowercased().contains("sso.html") else {
            return
        }
        
        webView.evaluateJavaScript("sessionStorage.getItem('geotab_sso_credentials');") { result, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.dismissWith(error: GeotabDriveErrors.SamlLoginError(error: SsoError.sessionRetrieveFailedError.rawValue))
                    
                }
            } else {
                guard let s = result as? String else {
                    DispatchQueue.main.async {
                        self.dismissWith(error: GeotabDriveErrors.SamlLoginError(error: SsoError.sessionParseFailedError.rawValue))
                    }
                    return
                }
                do {
                    let array = [s]
                    let json: Data = try JSONSerialization.data(withJSONObject: array, options: [])
                    var data: String = String(data: json, encoding: .utf8)!
                    data = String(data.dropFirst().dropLast())
                    DispatchQueue.main.async {
                        self.dismissWith(result: data)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.dismissWith(error: GeotabDriveErrors.SamlLoginError(error: SsoError.sessionParseFailedError.rawValue))
                    }
                }
            }
        }
    }
}
