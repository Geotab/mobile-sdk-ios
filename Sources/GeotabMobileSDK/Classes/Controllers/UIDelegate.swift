import WebKit

protocol UIHostController: UIViewController {
}

class UIDelegate: NSObject, WKUIDelegate {
    
    private weak var hostController: UIHostController?
    
    private lazy var languageBundle: Bundle? = {
        GeotabMobileSDK.languageBundle()
    }()
    
    init(hostController: UIHostController) {
        self.hostController = hostController
    }
    
    private func checkDeps() -> (Bundle, UIViewController)? {
        guard let languageBundle,
              let hostController,
              hostController.view.window != nil else {
            return nil
        }
        return (languageBundle, hostController)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        guard let (languageBundle, hostController) = checkDeps() else {
            completionHandler()
            return
        }
        
        let closeText = NSLocalizedString("Close", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: closeText, style: .default, handler: { _ in
            completionHandler()
        }))

        hostController.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        guard let (languageBundle, hostController) = checkDeps() else {
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

        hostController.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard let (languageBundle, hostController) = checkDeps() else {
            completionHandler(nil)
            return
        }

        let okText = NSLocalizedString("OK", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let cancelText = NSLocalizedString("Cancel", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)

        alertController.addTextField { (textField) -> Void in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: okText, style: .default, handler: { _ in
            let input = alertController.textFields?.first?.text
            completionHandler(input)
        }))

        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { _ in
            completionHandler(nil)
        }))

        hostController.present(alertController, animated: true, completion: nil)
    }
}
