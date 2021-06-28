//
//  MyGeotabViewController.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-10-07.
//

import WebKit
import SafariServices
import Mustache

/**
 MyGeotab's View Controller and API interface. Everthing you need to launch a MyGeotab. Only one instance should be created.
 
 - Extends: WebDriveDelegate. Provides modules functions to push 'window' CustomEvent to the Web Drive.
 */
public class MyGeotabViewController: UIViewController, WKScriptMessageHandler, ViewPresenter {
    
    private lazy var contentController: WKUserContentController = {
        let controller = WKUserContentController()
        return controller
    }()
    
    private lazy var moduleScripts: String = {
        var scripts = """
        window.\(Module.geotabModules) = {};
        window.\(Module.geotabNativeCallbacks) = {};
        """

        for module in self.modules {
            self.webviewConfig.userContentController.add(self, name: module.name)
            scripts += module.scripts()
        }
        
        let deviceReadyTemplate = try! Module.templateRepo.template(named: "Module.DeviceReady.Script")
        scripts += (try? deviceReadyTemplate.render()) ?? ""
        
        // Following line is important, without it, WKwebview will report error
        // Without it, following line will error out with:
        // Optional(Error Domain=WKErrorDomain Code=5 "JavaScript execution returned a result of an unsupported type" UserInfo={NSLocalizedDescription=JavaScript execution returned a result of an unsupported type})
        scripts += "\"success\";"
        return scripts
    }()

    private let webviewConfig = WKWebViewConfiguration()
    
    private lazy var webViewNavigationFailedView: WebViewNavigationFailedView = {
        let myClassNib = UINib(nibName: "WebViewNavigationFailedView", bundle: Bundle.module)
        let view = myClassNib.instantiate(withOwner: self, options: nil).first as! WebViewNavigationFailedView
        view.webView = self.webView
        view.frame = UIScreen.main.bounds
        view.isHidden = true
        view.configureXib()
        return view
    }()
    
    /**
     A callback listener when Drive failed to load from the server in case of network issue.
    */
    public var webAppLoadFailed: (() -> Void)?
    
    private lazy var webView: WKWebView = {
        webviewConfig.processPool = WKProcessPool()
        
        webviewConfig.mediaTypesRequiringUserActionForPlayback = []

        webviewConfig.allowsInlineMediaPlayback = true
        webviewConfig.suppressesIncrementalRendering = false
        webviewConfig.allowsAirPlayForMediaPlayback = true

        webviewConfig.userContentController = self.contentController
        let script = WKUserScript(source: self.moduleScripts, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        self.contentController.addUserScript(script)
        let device = DeviceModule.device
        webviewConfig.applicationNameForUserAgent = "MobileSDK/\(MobileSdkConfig.sdkVersion) \(device.appName)/\(device.version)"
        let view = WKWebView(frame: .zero, configuration: webviewConfig)
        view.navigationDelegate = self
        view.uiDelegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var modules: Set<Module> = []
    
    private lazy var templateRepo: TemplateRepository? = {
        let repo = TemplateRepository(bundle: Bundle.module, templateExtension: "js")
        repo.configuration.contentType = .text
        return repo
    }()
    
    private lazy var modulesInternal: Set<Module> = [
        AppModule(webDriveDelegate: self),
        BrowserModule(viewPresenter: self),
        DeviceModule(webDriveDelegate: self)
    ]
    
    /**
     Initializer
     
     - Parameters:
        - modules: User implemented thirdparty modules
     */
    public init(modules: Set<Module> = []) {
        super.init(nibName: nil, bundle: nil)
        Module.templateRepo = templateRepo
        self.modules.formUnion(modulesInternal)
        self.modules.formUnion(modules)
    }
    
    /// :nodoc:
    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }
    
    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.view.addSubview(webViewNavigationFailedView)
        let url = URL(string: "https://\(MyGeotabSdkConfig.serverAddress)/")!
        webViewNavigationFailedView.reloadURL = url
        webView.load(URLRequest(url: url))
    }
    
    /// :nodoc:
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let msg = message.body as? String else {
            return
        }
        let module = message.name
        let data = Data(msg.utf8)
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return
            }
            guard let function = json["function"] as? String else {
                return
            }
            guard let callback = json["callback"] as? String else {
                return
            }
            let params = json["params"]
            guard let moduleFunction = findModuleFunction(module: module, function: function) else {
                return
            }
            callModuleFunction(moduleFunction: moduleFunction, callback: callback, params: params)
        } catch {
            
        }
    }
    
    private func callModuleFunction(moduleFunction: ModuleFunction, callback: String, params: Any?) {
        moduleFunction.handleJavascriptCall(argument: params) { result in
            switch result {
            case .success(let result):
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("""
                        \(callback)(null, \(result));
                    """)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("""
                        \(callback)(new Error("\(error.localizedDescription)"));
                    """)
                }
            }
            
        }
    }

}

/// :nodoc:
extension MyGeotabViewController: ModuleContainerDelegate {
    /// :nodoc:
    public func findModuleFunction(module: String, function: String) -> ModuleFunction? {
        guard let mod = modules.first(where: { $0.name == module }) else {
            return nil
        }
        return mod.findFunction(name: function)
    }
    
    /// :nodoc:
    public func findModule(module: String) -> Module? {
        return modules.first(where: { $0.name == module })
    }
}

/// :nodoc:
extension MyGeotabViewController: WKNavigationDelegate {
    /// :nodoc:
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webViewNavigationFailedView.isHidden = false
        webAppLoadFailed?()
    }
    
    /// :nodoc:
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webViewNavigationFailedView.isHidden = false
        webAppLoadFailed?()
    }
}

extension MyGeotabViewController: WKUIDelegate {
    /// :nodoc:
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let url = navigationAction.request.url {
                UIApplication.shared.openURL(url)
            }
        }
        return nil
    }
}

extension MyGeotabViewController: WebDriveDelegate {

    /**
     Push a `window` `CustomEvent` to Web Drive.
     
     - Parameters:
        - ModuleEvent: Mimic of HTML5 `CustomEvent. `params` corresponds to JSON stringified javascript object having the optional fied 'details'.
            ` https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
     
     ### Example
     ```swift
     driveVC.push(moduleEvent: ModuleEvent(event: "testEvent", params: "{detail: 321}"))
     ```
     */
    func push(moduleEvent: ModuleEvent) {
        let script = """
            window.dispatchEvent(new CustomEvent("\(moduleEvent.event)", \(moduleEvent.params)));
        """
        self.webView.evaluateJavaScript(script)
    }
    
    /**
     Evaluate a custom javascript code in Web Drive.
     */
    func evaluate(script: String, completed: @escaping (Result<Any?, Error>) -> Void) {
        self.webView.evaluateJavaScript(script) { result, error in
            if error != nil {
                completed(Result.failure(error!))
            } else {
                completed(Result.success(result))
            }
        }
    }
    
}

extension MyGeotabViewController {
    /**
    Set `LastServerAddressUpdated` callback listener. Such event is sent by MyGeotab to notify impelementor that a designated "server address" should be used for future launches. Implementor should save the new server address in persistent storage. In the future launches, app should set the MyGeotabSdkConfig.serverAddress with the stored new address before creating an instance of MyGeotabViewController. Note such address is not the same as the counterparty one in DriveViewController.
     
     - Parameters:
        - callback: `LastServerAddressUpdatedCallbackType`
     */
    public func setLastServerAddressUpdatedCallback(_ callback: @escaping LastServerAddressUpdatedCallbackType) {
        guard let appModule = findModule(module: "app") as? AppModule else {
            return
        }
        appModule.lastServerAddressUpdated = callback
    }
    
    /**
    Clear `LastServerAddressUpdated` callback listener.
     */
    public func clearLastServerAddressUpdatedCallback() {
        guard let appModule = findModule(module: "app") as? AppModule else {
            return
        }
        appModule.lastServerAddressUpdated = nil
    }
}


