public import WebKit
import SafariServices
import Mustache

/**
 MyGeotab's View Controller and API interface. Everthing you need to launch a MyGeotab. Only one instance should be created.
 */
public class MyGeotabViewController: SDKViewController {
    
    @TaggedLogger("MyGeotabViewController")
    internal var logger
    
    private lazy var modulesInternal: Set<Module> = [
        AppModule(scriptGateway: scriptDelegate, options: options),
        BrowserModule(viewPresenter: self),
        DeviceModule(),
        PrintModule(viewPresenter: self),
        SsoModule(viewPresenter: self),
        LocalNotificationModule(options: options)
    ]
    
    /**
     Initializer
     
     - Parameters:
     - modules: User implemented thirdparty modules
     */
    public override init(modules: Set<Module> = [], options: MobileSdkOptions = .default) {
        super.init(modules: modules, options: options)
        self.modules.formUnion(modulesInternal)
    }
    
    /// :nodoc:
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = URL(string: "https://\(MyGeotabSdkConfig.serverAddress)/") {
            webViewNavigationFailedView.reloadURL = url
            $logger.info("Opening URL:\(url.absoluteString)")
            webView.load(URLRequest(url: url))
        }
    }
}

extension MyGeotabViewController: PrintViewPresenter {
    func presentPrintController(completion: @escaping () -> Void) {
        let controller = UIPrintInteractionController.shared
        controller.printFormatter = webView.viewPrintFormatter()
        controller.present(animated: true) { _, _, _ in
            completion()
        }
    }
}
