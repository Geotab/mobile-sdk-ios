import WebKit
import SafariServices
import Mustache

/**
 MyGeotab's View Controller and API interface. Everthing you need to launch a MyGeotab. Only one instance should be created.
 */
public class MyGeotabViewController: SDKViewController {
    
    private lazy var modulesInternal: Set<Module> = [
        AppModule(scriptGateway: scriptDelegate, options: options),
        BrowserModule(viewPresenter: self),
        DeviceModule(),
        PrintModule(scriptGateway: scriptDelegate, viewPresenter: self),
        SsoModule(viewPresenter: self),
        LocalNotificationModule(options: options)
    ]
    
    /**
     Initializer
     
     - Parameters:
     - modules: User implemented thirdparty modules
     */
    public init(modules: Set<Module> = []) {
        super.init(modules: modules)
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
