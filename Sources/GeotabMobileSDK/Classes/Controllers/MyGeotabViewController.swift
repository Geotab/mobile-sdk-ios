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
        AppModule(scriptGateway: scriptDelegate, options: options, bottomSafeAreaColorHandler: { [weak self] color in
            self?.bottomSafeAreaView.setColor(color)
        }),
        BrowserModule(viewPresenter: self),
        DeviceModule(),
        PrintModule(viewPresenter: self),
        SsoModule(viewPresenter: self),
        LocalNotificationModule(options: options, adapter: notificationAdapter),
        AuthModule()
    ]
    
    /**
     Initializer
     
     - Parameters:
     - modules: User implemented thirdparty modules
     */
    var pendingCustomPath: String?

    private let bottomSafeAreaView = BottomSafeAreaView()

    /// Nil uses the system's notification center. Only the initializer below sets it.
    private var notificationAdapter: (any UserNotifcationAdapter)?

    public override init(modules: Set<Module> = [], options: MobileSdkOptions = .default) {
        super.init(modules: modules, options: options)
        self.modules.formUnion(modulesInternal)
    }

    /// Lets tests build the controller around their own notification adapter, as they cannot reach the system's.
    init(modules: Set<Module> = [], options: MobileSdkOptions = .default, notificationAdapter: any UserNotifcationAdapter) {
        self.notificationAdapter = notificationAdapter
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
        
        // Below the navigation failed view, so a failure still covers the whole screen.
        bottomSafeAreaView.install(in: view, above: webView)

        let path = pendingCustomPath.map { "#\($0)" } ?? ""
        pendingCustomPath = nil
        if let url = URL(string: "https://\(MyGeotabSdkConfig.serverAddress)/\(path)") {
            webViewNavigationFailedView.reloadURL = url
            $logger.debug("Opening URL:\(url.absoluteString)")
            webView.load(URLRequest(url: url))
        }
    }

    override func navigationFailedScreenDidShow() {
        // The web app does not own this screen and cannot hand the area back, so the app does.
        bottomSafeAreaView.setColor(nil)
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
