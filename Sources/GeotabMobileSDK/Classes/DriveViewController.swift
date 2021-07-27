// Copyright © 2021 Geotab Inc. All rights reserved.

import WebKit
import SafariServices
import Mustache

/**
 Drive's View Controller and API interface. Everthing you need to launch a Drive. Only one instance should be created.
 
 - Extends: WebDriveDelegate. Provides modules functions to push 'window' CustomEvent to the Web Drive.
 */
open class DriveViewController: UIViewController, WKScriptMessageHandler, ViewPresenter {
        
    private var completedViewDidLoaded = false
    
    private var loginCredentials: CredentialResult?
    
    /**
     Indicates whether phone is in charging state.
     */
    public var isCharging: Bool {
        get {
            guard let batteryModule = findModule(module: "battery") as? BatteryModule else {
                return false
            }
            return batteryModule.isCharging
        }
    }
    
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
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var modules: Set<Module> = []
    
    private lazy var templateRepo: TemplateRepository? = {
        let repo = TemplateRepository(bundle: Bundle.module, templateExtension: "js")
        repo.configuration.contentType = .text
        return repo
    }()
    
    // Add intenrnal Addons here

    private lazy var modulesInternal: Set<Module> = [
        AppModule(webDriveDelegate: self),
        ScreenModule(),
        UserModule(webDriveDelegate: self),
        DeviceModule(webDriveDelegate: self),
        StateModule(webDriveDelegate: self),
        LocalNotificationModule(),
        SpeechModule(),
        BrowserModule(viewPresenter: self),
        ConnectivityModule(webDriveDelegate: self),
        BatteryModule(webDriveDelegate: self),
        FileSystemModule(),
        CameraModule(webDriveDelegate: self, viewPresenter: self, moduleContainer: self),
        PhotoLibraryModule(webDriveDelegate: self, viewPresenter: self, moduleContainer: self),
        GeolocationModule(webDriveDelegate: self),
        MotionModule(webDriveDelegate: self),
        IoxBleModule(webDriveDelegate: self),
        SsoModule(viewPresenter: self)
    ]
    /**
     Initializer
     
     - Parameters:
        - modules: User implemented thirdparty modules
     */
    public init(modules: Set<Module> = []) {
        super.init(nibName: nil, bundle: Bundle.module)
        Module.templateRepo = templateRepo
        self.modules.formUnion(modulesInternal)
        self.modules.formUnion(modules)
    }
    
    /// :nodoc:
    required public init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: Bundle.module)
    }

    /// :nodoc:
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        var url: URL
        view.addSubview(webViewNavigationFailedView)
        
        if let credentialResult = loginCredentials {
            let urlString = "https://\(DriveSdkConfig.serverAddress)/drive/default.html#ui/login,(server:'\(credentialResult.path)',credentials:(database:'\(credentialResult.credentials.database)',sessionId:'\(credentialResult.credentials.sessionId)',userName:'\(credentialResult.credentials.userName)'))"
            url = URL(string: urlString)!
            webViewNavigationFailedView.reloadURL = url
            webView.load(URLRequest(url: url))
        } else {
            url = URL(string: "https://\(DriveSdkConfig.serverAddress)/drive/default.html")!
            webViewNavigationFailedView.reloadURL = url
            webView.load(URLRequest(url: url))
            
        }
        completedViewDidLoaded = true
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
    
    /**
     Cancelling a login request. When user clicked Add CoDriver in Drive, but decided not to proceed and want to cancel that request, this function must be called. What this function do is to navigate the Drive to the previously non-login page. If the login request is main driver login, calling this function will result dismissing the DriveViewController.
     */
    public func cancelLogin() {
        if let fragment = webView.backForwardList.currentItem?.url.fragment, !fragment.contains("login") {
            return
        }
        for (_, itm) in webView.backForwardList.backList.enumerated().reversed() {
            if let fragment = itm.url.fragment, !fragment.lowercased().contains("login") {
                webView.go(to: itm)
                return
            }
            
        }
        dismiss(animated: true)
    }
    
}

/// :nodoc:
extension DriveViewController: ModuleContainerDelegate {
    public func findModuleFunction(module: String, function: String) -> ModuleFunction? {
        guard let mod = modules.first(where: { $0.name == module }) else {
            return nil
        }
        return mod.findFunction(name: function)
    }
    
    public func findModule(module: String) -> Module? {
        return modules.first(where: { $0.name == module })
    }
}

/// :nodoc:
extension DriveViewController: WKNavigationDelegate {
    /// :nodoc:
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.request.url?.absoluteString.lowercased().hasPrefix("https") == true else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    /// :nodoc:
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let err = error as? NSError, err.code == NSURLErrorCancelled {
            return
        }
        webViewNavigationFailedView.isHidden = false
        webAppLoadFailed?()
    }
    
    /// :nodoc:
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webViewNavigationFailedView.isHidden = false
        webAppLoadFailed?()
    }
}

extension DriveViewController: WebDriveDelegate {

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

extension DriveViewController {
    /**
     Get all driver users signed in.
     
     - Parameters:
        - callback: Result is given as a JSON string representing an array of Users
     */
    public func getAllUsers(_ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: "user", function: "getAll") as? GetAllUsersFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(callback)
    }
    
    /**
    Get the HOS Rule Set.
     
     - Parameters:
        - callback: Result is given as a JSON string representing a HosRuleset
     */
    public func getHosRuleSet(_ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: "user", function: "getHosRuleSet") as? GetHosRuleSetFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(callback)
    }
    
    /**
    Get the User Availability.
     
     - Parameters:
        - callback: Result is given as a JSON string representing a DutyStatusAvailability
     */
    public func getUserAvailability(_ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: "user", function: "getAvailability") as? GetAvailabilityFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(callback)
    }
    
    /**
    Get the User Violations.
     
     - Parameters:
        - callback: Result is given as a JSON string representing a DutyStatusViolation
     */
    public func getUserViolations(_ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: "user", function: "getViolations") as? GetViolationsFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(callback)
    }
    
    /**
    Set a driver in driver seat.
     
     - Parameters:
        - driverId: String
        - callback: Result is given as a JSON string representing a User
     */
    public func setDriverSeat(driverId: String, _ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: "user", function: "setDriverSeat") as? SetDriverSeatFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(driverId: driverId, callback)
    }
    
    /**
    Get the `Go Device` of Drive's `state`.
     
     - Parameters:
        - callback: Result is given as a JSON string representation of a GoDevice
     */
    public func getStateDevice(_ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: "state", function: "device") as? DeviceFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(callback)
    }

    /**
    Set a custom speech Engine to replace the default one comes with the SDK.
     
     - Parameters:
        - speechEngine: `SpeechEngine`
     */
    public func setSpeechEngine(speechEngine: SpeechEngine) {
        guard let speechModule = modules.first(where: { $0.name == "speech" }) as? SpeechModule else {
            return
        }
        speechModule.setSpeechEngine(speechEngine: speechEngine)
    }
    
    /**
    Set a new Geotab session for driver or co-driver. Setting a new session means adding a new driver to Drive. In case the given session is invalid, `Login Required` event will be triggered. See `setLoginRequiredCallback` for more detail.
     
     - Parameters:
        - credentialResult: `CredentialResult`.
        - isCoDriver: Bool. Indicate if its' for a co-driver login.
     */
    public func setSession(credentialResult: CredentialResult, isCoDriver: Bool = false){
        self.loginCredentials = credentialResult
        var urlString = "https://\(DriveSdkConfig.serverAddress)/drive/default.html#ui/login,(server:'\(credentialResult.path)',credentials:(database:'\(credentialResult.credentials.database)',sessionId:'\(credentialResult.credentials.sessionId)',userName:'\(credentialResult.credentials.userName)'))"
        if isCoDriver {
            urlString = "https://\(DriveSdkConfig.serverAddress)/drive/default.html#ui/login,(addCoDriver:!t,server:'\(credentialResult.path)',credentials:(database:'\(credentialResult.credentials.database)',sessionId:'\(credentialResult.credentials.sessionId)',userName:'\(credentialResult.credentials.userName)'))"
        }
        if completedViewDidLoaded, let url = URL(string: urlString) {
            webViewNavigationFailedView.reloadURL = url
            webView.load(URLRequest(url:url))
        }
    }
    
    /**
    Set `DriverActionNecessary` callback to listen for such event sent from Web Drive.
     
     - Parameters:
        - callback: `DriverActionNecessaryCallbackType`
     */
    public func setDriverActionNecessaryCallback(_ callback: @escaping DriverActionNecessaryCallbackType) {
        guard let userModule = findModule(module: "user") as? UserModule else {
            return
        }
        userModule.driverActionNecessaryCallback = callback
    }
    
    /**
    Clear `DriverActionNecessary` callback listener.
     */
    public func clearDriverActionNecessaryCallback() {
        guard let userModule = findModule(module: "user") as? UserModule else {
            return
        }
        userModule.driverActionNecessaryCallback = nil
    }
    
    /**
    Set `PageNavigation` callback listener.
     
     - Parameters:
        - callback: `PageNavigationCallbackType`
     */
    public func setPageNavigationCallback(_ callback: @escaping PageNavigationCallbackType) {
        guard let userModule = findModule(module: "user") as? UserModule else {
            return
        }
        userModule.pageNavigationCallback = callback
    }
    
    /**
    Clear `PageNavigation` callback listener.
     */
    public func clearPageNavigationCallback() {
        guard let userModule = findModule(module: "user") as? UserModule else {
            return
        }
        userModule.pageNavigationCallback = nil
    }
    
    /**
     Set a callback to listen for session changes. That includes: no session, invalid session, session expired, co-driver login is requested.
     
     - Parameters:
        - callback: `LoginRequiredCallbackType`
                - status: `""` `"LoginRequired"`, `"AddCoDriver"`.
                - errorMessage: Error happened during login process and error info is given in `errorMessage`.
     
     There are three defined values and variance of different error messages that could be passed in the callback.

     - "", empty string, indicates no login required or login is successful, or the login is in progress. At this state, implementor should presents the DriveViewController/Fragment.
     - "LoginRequired": indicates the login UI is going to show a login form(No valid user is available or the current activeSession is expired/invalid). At this state, implementor presents its own login screen.
     - "AddCoDriver": indicates that a co-driver login is requested. At this state, implementor presents its own co-driver login screen.
     - Any error message, any other error messages. At this state, implementor presents its own login screen.

     After receiving such session expired callback call. Integrator usually dismisses the presented `DriveViewController` and present user with its Login screen.

     */
    public func setLoginRequiredCallback(_ callback: @escaping LoginRequiredCallbackType) {
        guard let userModule = findModule(module: "user") as? UserModule else {
            return
        }
        userModule.loginRequiredCallback = callback
    }
    
    /**
    Clear `LoginRequired` callback listener.
     */
    public func clearLoginRequiredCallback() {
        guard let userModule = findModule(module: "user") as? UserModule else {
            return
        }
        userModule.loginRequiredCallback = nil
    }
    
    /**
    Set `LastServerAddressUpdated` callback listener. Such event is sent by Drive to notify impelementor that a designated "server address" should be used for future launches. Implementor should save the new server address in persistent storage. In the future launches, app should set the DriveSdkConfig.serverAddress with the stored new address before creating an instance of DriveViewController. Note such address is not the same as the counterparty one in MyGeotabViewController.
     
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
