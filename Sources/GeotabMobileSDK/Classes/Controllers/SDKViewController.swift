public import WebKit
import SafariServices
import Mustache

/// :nodoc:
open class SDKViewController: UIViewController, ViewPresenter {

    @TaggedLogger("SDKViewController")
    private var logger
    
    internal lazy var scriptDelegate: ScriptDelegate = {
        ScriptDelegate(scriptEvaluator: self)
    }()

    internal lazy var userContentControllerDelegate: UserContentControllerDelegate = {
        UserContentControllerDelegate(modules: modules, scriptGateway: scriptDelegate)
    }()

    internal lazy var navigationDelegate: NavigationDelegate = {
        NavigationDelegate(navigationHost: self)
    }()

    internal lazy var uiDelegate: UIDelegate = {
        UIDelegate(hostController: self)
    }()

    internal lazy var webViewNavigationFailedView: WebViewNavigationFailedView = {
        let myClassNib = UINib(nibName: "WebViewNavigationFailedView", bundle: Bundle.module)
        let view = myClassNib.instantiate(withOwner: self, options: nil).first as! WebViewNavigationFailedView
        view.webView = self.webView
        view.frame = UIScreen.main.bounds
        view.isHidden = true
        view.configureXib()
        return view
    }()
        
    internal lazy var webView: WKWebView = {
        WKWebView.create(userContentControllerDelegate: userContentControllerDelegate,
                         navigationDelegate: navigationDelegate,
                         uiDelegate: uiDelegate,
                         useAppBoundDomains: options.useAppBoundDomains,
                         makeWebViewInspectable: options.makeWebViewInspectable,
                         userAgentTokens: options.userAgentTokens)
    }()
    
    internal var modules: Set<Module> = []
    
    private lazy var templateRepo: TemplateRepository? = {
        let repo = TemplateRepository(bundle: Bundle.module, templateExtension: "js")
        repo.configuration.contentType = .text
        return repo
    }()
    
    /**
     A callback listener when Drive failed to load from the server in case of network issue.
    */
    public var webAppLoadFailed: (() -> Void)?
    
    internal let options: MobileSdkOptions

    /**
     Initializer
     
     - Parameters:
        - modules: User implemented third party modules
        - useAppBoundDomains: On iOS 14 or better enable App Bound Domains in the embedded webview
     */
    public init(modules: Set<Module> = [], options: MobileSdkOptions = .default) {
        self.options = options
        super.init(nibName: nil, bundle: Bundle.module)
        Module.templateRepo = templateRepo
        self.modules.formUnion(modules)
    }
    
    /// :nodoc:
    required public init?(coder: NSCoder) {
        options = .default
        super.init(nibName: nil, bundle: Bundle.module)
    }

    private func pin(subview: UIView) {
        subview.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    
    /// :nodoc:
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        pin(subview: webView)
        webViewNavigationFailedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webViewNavigationFailedView)
        pin(subview: webViewNavigationFailedView)
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Only clearing volatile memory (RAM).
        WKWebsiteDataStore.default().removeData(
            ofTypes: [WKWebsiteDataTypeMemoryCache],
            modifiedSince: Date.distantPast
        ) { [weak self] in
            self?.$logger.info("Memory warning detected. Purging volatile memory cache.")
        }
    }

    deinit {
        // Clean up WKWebView delegates to ensure proper deallocation
        if isViewLoaded {
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            $logger.debug("SDKViewController deinitialized")
        }
    }
}

/// :nodoc:
extension SDKViewController {
    public func findModuleFunction(module: String, function: String) -> ModuleFunction? {
        modules.findFunction(in: module, function: function)
    }
    
    public func findModule(module: String) -> Module? {
        modules.first(where: { $0.name == module })
    }
}

/// :nodoc:
extension Set where Element == Module {
    func findFunction (in module: String, function: String) -> ModuleFunction? {
        guard let module = first(where: { $0.name == module }) else {
            return nil
        }
        return module.findFunction(name: function)
    }
}

/// :nodoc:
extension SDKViewController: NavigationHost {
    var useAppBoundDomains: Bool {
        options.useAppBoundDomains
    }
    
    func navigationFailed(with error: NSError) {
        showNavigationFailedScreen(for: error as NSError)
        webAppLoadFailed?()
    }

    private func showNavigationFailedScreen(for error: NSError) {
        webViewNavigationFailedView.isHidden = false
        webViewNavigationFailedView.errorInfoLabel.text = "\(error.domain) \(error.code) \(error.localizedDescription)"
    }
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

/// :nodoc:
extension SDKViewController: UIHostController {
}

/// :nodoc:
extension SDKViewController: ScriptEvaluating {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, (any Error)?) -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
        }
    }
}
