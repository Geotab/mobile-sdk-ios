import WebKit
import os.log

protocol UIHostController: UIViewController {
}

class UIDelegate: NSObject, WKUIDelegate {
    
    private weak var hostController: (any UIHostController)?
    
    private lazy var languageBundle: Bundle? = {
        GeotabMobileSDK.languageBundle()
    }()
    
    var alertCompletionHandler: (() -> Void)?
    private static let log = OSLog(subsystem: "com.geotab.mobileSDK", category: "UIDelegate")

    init(hostController: any UIHostController) {
        self.hostController = hostController
    }
    
    private func checkDeps() -> (Bundle, UIViewController)? {
        guard let languageBundle,
              let hostController,
              hostController.view.window != nil
        else {
            return nil
        }
        return (languageBundle, hostController)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {

        guard let (languageBundle, hostController) = checkDeps() else {
            os_log(.debug, log: UIDelegate.log, "UIDelegate: suppressing JS alert — host controller not in window hierarchy")
            completionHandler()
            return
        }

        // Concurrent dialog guard - if another dialog is pending, resolve with safe default
        if alertCompletionHandler != nil {
            completionHandler()
            return
        }

        alertCompletionHandler = completionHandler

        let closeText = NSLocalizedString("Close", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: closeText, style: .default, handler: { _ in
            let handler = self.alertCompletionHandler
            self.alertCompletionHandler = nil
            handler?()
        }))

        // Present on topmost VC to avoid "already presenting" failure
        let presenter = hostController.presentedViewController ?? hostController
        presenter.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {

        guard let (languageBundle, hostController) = checkDeps() else {
            os_log(.debug, log: UIDelegate.log, "UIDelegate: suppressing JS confirm — host controller not in window hierarchy")
            completionHandler(false)
            return
        }

        // Concurrent dialog guard - if another dialog is pending, resolve with safe default
        if alertCompletionHandler != nil {
            completionHandler(false)
            return
        }

        alertCompletionHandler = { completionHandler(false) }

        let okText = NSLocalizedString("OK", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let cancelText = NSLocalizedString("Cancel", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: okText, style: .default, handler: { _ in
            // Nil the deinit safety handler (false-default) since we're handling the result directly.
            // Strong capture of self ensures UIDelegate outlives this closure.
            self.alertCompletionHandler = nil
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { _ in
            let handler = self.alertCompletionHandler
            self.alertCompletionHandler = nil
            handler?()
        }))

        // Present on topmost VC to avoid "already presenting" failure
        let presenter = hostController.presentedViewController ?? hostController
        presenter.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard let (languageBundle, hostController) = checkDeps() else {
            os_log(.debug, log: UIDelegate.log, "UIDelegate: suppressing JS prompt — host controller not in window hierarchy")
            completionHandler(nil)
            return
        }

        // Concurrent dialog guard - if another dialog is pending, resolve with safe default
        if alertCompletionHandler != nil {
            completionHandler(nil)
            return
        }

        alertCompletionHandler = { completionHandler(nil) }

        let okText = NSLocalizedString("OK", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let cancelText = NSLocalizedString("Cancel", tableName: "Localizable", bundle: languageBundle, comment: "nil")
        let alertController = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: okText, style: .default, handler: { _ in
            let input = alertController.textFields?.first?.text
            // Nil the deinit safety handler (nil-default) since we're handling the result directly.
            // Strong capture of self ensures UIDelegate outlives this closure.
            self.alertCompletionHandler = nil
            completionHandler(input)
        }))

        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { _ in
            let handler = self.alertCompletionHandler
            self.alertCompletionHandler = nil
            handler?()
        }))

        // Present on topmost VC to avoid "already presenting" failure
        let presenter = hostController.presentedViewController ?? hostController
        presenter.present(alertController, animated: true, completion: nil)
    }
    
    deinit {
        let handler = alertCompletionHandler
        alertCompletionHandler = nil
        // WebKit requires every JS dialog completion handler be called exactly once.
        // If UIDelegate is torn down with a pending handler (e.g. host VC released while
        // an alert was visible), call it here as a safety net. The handler closure is a
        // standalone block and is safe to invoke after the originating web view has been
        // released — WebKit ignores stale dialog responses gracefully.
        if Thread.isMainThread {
            handler?()
        } else {
            DispatchQueue.main.async { handler?() }
        }
    }
}
