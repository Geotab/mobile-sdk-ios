import WebKit
import os.log

protocol UIHostController: UIViewController {
}

class UIDelegate: NSObject, WKUIDelegate {
    
    private weak var hostController: (any UIHostController)?
    private let mediaPermissions: any MediaPermissionProviding
    private let usageDescription: (String) -> String?
    private let configuredServer: () -> String?
    private let applicationState: () -> UIApplication.State
    private var pendingMediaDecision: MediaDecisionOnce?
    
    private lazy var languageBundle: Bundle? = {
        GeotabMobileSDK.languageBundle()
    }()
    
    var alertCompletionHandler: (() -> Void)?
    private static let log = OSLog(subsystem: "com.geotab.mobileSDK", category: "UIDelegate")

    init(hostController: any UIHostController,
         mediaPermissions: any MediaPermissionProviding = SystemMediaPermissionProvider(),
         usageDescription: @escaping (String) -> String? = { Bundle.main.object(forInfoDictionaryKey: $0) as? String },
         configuredServer: (() -> String?)? = nil,
         applicationState: @escaping () -> UIApplication.State = { UIApplication.shared.applicationState }) {
        self.hostController = hostController
        self.mediaPermissions = mediaPermissions
        self.usageDescription = usageDescription
        self.configuredServer = configuredServer ?? { usageDescription("server-address") }
        self.applicationState = applicationState
    }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decideMediaCapture(protocol: origin.protocol, host: origin.host, port: origin.port,
                           isMainFrame: frame.isMainFrame, topLevelURL: webView.url,
                           type: type, decisionHandler: decisionHandler)
    }

    func decideMediaCapture(protocol scheme: String, host: String, port: Int, isMainFrame: Bool,
                            topLevelURL: URL?, type: WKMediaCaptureType,
                            decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        let decision = MediaDecisionOnce(topLevelHost: type == .camera ? nil : (topLevelURL?.host ?? ""), decisionHandler)
        MediaDecisionOnce.onMain { [weak self] in
            guard let self else {
                decision.resolve(.deny)
                return
            }
            if type == .camera {
                decision.resolve(.prompt)
                return
            }
            guard self.hasUsageDescription("NSMicrophoneUsageDescription"),
                  type != .cameraAndMicrophone || self.hasUsageDescription("NSCameraUsageDescription") else {
                decision.resolve(.deny, reason: "no usage key")
                return
            }
            guard type == .microphone || type == .cameraAndMicrophone, self.pendingMediaDecision == nil else {
                decision.resolve(.deny, reason: "unsupported capture type or permission request pending")
                return
            }
            switch WebViewAudioOriginPolicy.decision(protocol: scheme, host: host, port: port,
                isMainFrame: isMainFrame, topLevelURL: topLevelURL, configuredServer: self.configuredServer()) {
            case .allow: break
            case .prompt:
                decision.resolve(.prompt, reason: "Geotab domain is not a MyGeotab host")
                return
            case .deny(let reason):
                decision.resolve(.deny, reason: reason)
                return
            }
            guard self.applicationState() != .background, self.checkDeps() != nil else {
                decision.resolve(.deny, reason: "app background or host not in window")
                return
            }
            self.pendingMediaDecision = decision
            self.authorizeRecord(type: type, decision: decision)
        }
    }

    private func hasUsageDescription(_ key: String) -> Bool {
        !(usageDescription(key)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private func finishMedia(_ decision: MediaDecisionOnce, granted: Bool, reason: String = "OS permission denied") {
        guard pendingMediaDecision === decision else { return }
        pendingMediaDecision = nil
        decision.resolve(granted ? .grant : .deny, reason: reason)
    }

    private func authorizeRecord(type: WKMediaCaptureType, decision: MediaDecisionOnce) {
        // A known camera denial must not cause an unnecessary microphone prompt.
        if type == .cameraAndMicrophone && mediaPermissions.cameraPermission == .denied {
            finishMedia(decision, granted: false)
            return
        }
        switch mediaPermissions.recordPermission {
        case .denied: finishMedia(decision, granted: false)
        case .granted: authorizeCamera(type: type, decision: decision)
        case .undetermined:
            guard applicationState() == .active, checkDeps() != nil else {
                finishMedia(decision, granted: false, reason: "app not active or host not in window")
                return
            }
            mediaPermissions.requestRecordPermission { [weak self] granted in
                MediaDecisionOnce.onMain { [weak self] in
                    guard let self else {
                        decision.resolve(.deny)
                        return
                    }
                    guard self.pendingMediaDecision === decision else { return }
                    if granted { self.authorizeCamera(type: type, decision: decision) }
                    else { self.finishMedia(decision, granted: false) }
                }
            }
        }
    }

    private func authorizeCamera(type: WKMediaCaptureType, decision: MediaDecisionOnce) {
        guard type == .cameraAndMicrophone else {
            finishMedia(decision, granted: true)
            return
        }
        switch mediaPermissions.cameraPermission {
        case .denied: finishMedia(decision, granted: false)
        case .granted: finishMedia(decision, granted: true)
        case .undetermined:
            guard applicationState() == .active, checkDeps() != nil else {
                finishMedia(decision, granted: false, reason: "app not active or host not in window")
                return
            }
            mediaPermissions.requestCameraPermission { [weak self] granted in
                MediaDecisionOnce.onMain { [weak self] in
                    guard let self else {
                        decision.resolve(.deny)
                        return
                    }
                    self.finishMedia(decision, granted: granted)
                }
            }
        }
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
        pendingMediaDecision?.resolve(.deny)
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
