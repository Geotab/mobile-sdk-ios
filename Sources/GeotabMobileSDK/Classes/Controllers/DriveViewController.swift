import WebKit
import SafariServices
import Mustache

/**
 Drive's View Controller and API interface. Everthing you need to launch a Drive. Only one instance should be created.
 */

open class DriveViewController: SDKViewController {

    @TaggedLogger("DriveViewController")
    internal var logger
    
    internal var loginCredentials: CredentialResult?
    
    internal var customUrl: URL?

    // Add internal Addons here
    private lazy var modulesInternal: Set<Module> = [
        AppModule(scriptGateway: scriptDelegate, options: options),
        ScreenModule(),
        UserModule(scriptGateway: scriptDelegate),
        DeviceModule(),
        StateModule(scriptGateway: scriptDelegate),
        LocalNotificationModule(options: options),
        SpeechModule(),
        BrowserModule(viewPresenter: self),
        ConnectivityModule(scriptGateway: scriptDelegate),
        BatteryModule(scriptGateway: scriptDelegate),
        FileSystemModule(),
        CameraModule(viewPresenter: self),
        PhotoLibraryModule(viewPresenter: self),
        GeolocationModule(scriptGateway: scriptDelegate, options: options),
        IoxBleModule(scriptGateway: scriptDelegate),
        SsoModule(viewPresenter: self),
        AppearanceModule(scriptGateway: scriptDelegate, appearanceSource: self),
        SecureStorageModule(),
        DutyStatusLogModule(scriptGateway: scriptDelegate)
    ]
    
    /**
     Initializer
     
     - Parameters:
        - modules: User implemented third party modules
        - options: Optional behaviors for the view ocntrollerr
     */
    public override init(modules: Set<Module> = [], options: MobileSdkOptions = .default) {
        super.init(modules: modules, options: options)
        self.modules.formUnion(modulesInternal)        
    }
    
    /// :nodoc:
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// :nodoc:
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        if let credentialResult = loginCredentials {
            let urlString = "https://\(DriveSdkConfig.serverAddress)/drive/default.html#ui/login,(server:'\(credentialResult.path)',credentials:(database:'\(credentialResult.credentials.database)',sessionId:'\(credentialResult.credentials.sessionId)',userName:'\(credentialResult.credentials.userName)'))"
            let url = URL(string: urlString)!
            webViewNavigationFailedView.reloadURL = url
            webView.load(URLRequest(url: url))
        } else if let url = customUrl {
            // the full URL may contain credentials, e.g. "#login,(token:xxxx)", do not log
            $logger.info("Opening custom url with scheme \(url.scheme ?? "nil")")
            webView.load(URLRequest(url: url))
            customUrl = nil
        } else if let url = URL(string: "https://\(DriveSdkConfig.serverAddress)/drive/default.html") {
            // Add useServiceWorker to the URL params to have drive force on service workers when running against local host
            // } else if let url = URL(string: "https://\(DriveSdkConfig.serverAddress)/drive/default.html?useServiceWorker") {
            webViewNavigationFailedView.reloadURL = url
            webView.load(URLRequest(url: url))
        }
    }
}
