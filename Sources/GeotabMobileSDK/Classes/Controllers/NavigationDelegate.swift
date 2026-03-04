import WebKit

protocol NavigationHost: UIDocumentInteractionControllerDelegate {
    func navigationFailed(with error: NSError)
    var useAppBoundDomains: Bool { get }
}

/// :nodoc:
class NavigationDelegate: NSObject, WKNavigationDelegate {
    
    @TaggedLogger("NavigationDelegate")
    private var logger

    private var fileDestinationURL: URL?

    private weak var navigationHost: (any NavigationHost)?

    private lazy var boundDomains: [String] = {
        if navigationHost?.useAppBoundDomains ?? false,
           let values = Bundle.main.object(forInfoDictionaryKey: "WKAppBoundDomains") as? [String] {
            return values
        }
        return ["geotab.com"]
    }()
    
    init(navigationHost: any NavigationHost) {
        self.navigationHost = navigationHost
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        switch url.scheme {
        case "blob":
            guard url.absoluteString.lowercased().hasPrefix("blob:https") == true else {
                // the full URL may contain credentials, do not log it
                $logger.info("Navigation cancelled for page with unexpected blob scheme \(url.scheme ?? "nil")")
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.download)
            return
        case "https":
            break
        case "mailto", "tel", "sms":
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
            return
        case "about":
            break
        default:
            $logger.info("Navigation cancelled for page with unexpected scheme \(url.scheme ?? "nil")")
            decisionHandler(.cancel)
            return
        }

        if let frame = navigationAction.targetFrame,
           let domain = url.domain,
           frame.isMainFrame,
           !boundDomains.contains(domain) {
            $logger.warn("Navigating to out of bounds domain \(domain)")
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        navigationHost?.navigationFailed(with: error as NSError)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        if !FeatureFlag.ignoreRequestCancellationErrorsKillSwitch.isEnabled {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
        }
        
        if let error = error as? WKError,
           error.code == .navigationAppBoundDomain {
            $logger.warn("Navigating to out of bounds domain: \(error.localizedDescription)")
        }

        navigationHost?.navigationFailed(with: error as NSError)
    }
}

/// :nodoc:
extension NavigationDelegate: WKDownloadDelegate {

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let fileName = NSTemporaryDirectory() + suggestedFilename
        if FileManager.default.fileExists(atPath: fileName) {
            try? FileManager.default.removeItem(atPath: fileName)
        }
        let url = URL(fileURLWithPath: fileName)
        fileDestinationURL = url
        completionHandler(url)
    }

    func download(_ download: WKDownload, didFailWithError error: any Error, resumeData: Data?) {
        $logger.debug("Download failed: \(error)")
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let url = fileDestinationURL else {
            $logger.debug("Download completed with no file ")
            return
        }

        let documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController.delegate = navigationHost
        documentInteractionController.presentPreview(animated: true)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
}
