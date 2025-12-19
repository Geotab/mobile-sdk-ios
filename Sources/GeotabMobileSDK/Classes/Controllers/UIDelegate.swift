import WebKit

protocol UIHostController: UIViewController {
}

class UIDelegate: NSObject, WKUIDelegate {
    
    private weak var hostController: (any UIHostController)?
    
    private lazy var languageBundle: Bundle? = {
        GeotabMobileSDK.languageBundle()
    }()
    
    init(hostController: any UIHostController) {
        self.hostController = hostController
    }
    
    private func checkDeps() -> (Bundle, UIViewController)? {
        guard let languageBundle,
              let hostController else {
            return nil
        }
        return (languageBundle, hostController)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        guard let (languageBundle, hostController) = checkDeps() else {
            // No host controller available - call completion immediately
            completionHandler()
            return
        }
        
        let closeText = NSLocalizedString("Close", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: closeText, style: .default, handler: { _ in
            completionHandler()
        }))

        // Present on topmost VC to avoid "already presenting" failure
        let presenter = hostController.presentedViewController ?? hostController
        presenter.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        guard let (languageBundle, hostController) = checkDeps() else {
            // No host controller available - call completion with false
            completionHandler(false)
            return
        }
        
        let okText = NSLocalizedString("OK", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let cancelText = NSLocalizedString("Cancel", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: okText, style: .default, handler: { _ in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { _ in
            completionHandler(false)
        }))

        // Present on topmost VC to avoid "already presenting" failure
        let presenter = hostController.presentedViewController ?? hostController
        presenter.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard let (languageBundle, hostController) = checkDeps() else {
            // No host controller available - call completion with nil
            completionHandler(nil)
            return
        }

        let okText = NSLocalizedString("OK", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let cancelText = NSLocalizedString("Cancel", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: okText, style: .default, handler: { _ in
            let input = alertController.textFields?.first?.text
            completionHandler(input)
        }))

        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { _ in
            completionHandler(nil)
        }))

        // Present on topmost VC to avoid "already presenting" failure
        let presenter = hostController.presentedViewController ?? hostController
        presenter.present(alertController, animated: true, completion: nil)
    }
}
