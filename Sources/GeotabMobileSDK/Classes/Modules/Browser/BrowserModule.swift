import SafariServices

protocol InAppBrowser: AnyObject {
    var isBeingDismissed: Bool { get }
    func viewController() -> UIViewController
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

class BrowserModule: Module {
    static let moduleName = "browser"

    private weak var viewPresenter: (any ViewPresenter)?
    weak var inAppBrowser: (any InAppBrowser)?
    private let browserFactory: (URL) -> any InAppBrowser

    init(viewPresenter: any ViewPresenter,
         browserFactory: @escaping (URL) -> any InAppBrowser = { SFSafariViewController(url: $0) }) {
        self.viewPresenter = viewPresenter
        self.browserFactory = browserFactory
        super.init(name: BrowserModule.moduleName)
        functions.append(OpenBrowserWindowFunction(browserOpener: self))
        functions.append(CloseBrowserWindowFunction(browserCloser: self))
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        let extraTemplate = try! Module.templateRepo.template(named: "Module.Browser.Script")
        scripts += (try? extraTemplate.render()) ?? ""
    
        return scripts
    }
    
    func getBrowserWithUrl(url: URL) -> any InAppBrowser {
        return browserFactory(url)
    }
}

// MARK: - Default InAppBrowser is SFSafariViewController
extension SFSafariViewController: InAppBrowser {
    func viewController() -> UIViewController { self }
}

extension BrowserModule: BrowserWindowOpening {
    func openInExternalBrowser(url: URL) {
        UIApplication.shared.open(url)
    }
    
    func openInAppBrowser(url: URL) {
        if inAppBrowser != nil {
            inAppBrowser?.dismiss(animated: true, completion: nil)
            inAppBrowser = nil
        }
        
        let browser = getBrowserWithUrl(url: url)
        inAppBrowser = browser
        viewPresenter?.present(browser.viewController(), animated: true, completion: nil)
    }
}

extension BrowserModule: BrowserWindowClosing {
    func closeInAppBrowser() {
        if inAppBrowser != nil {
            if !inAppBrowser!.isBeingDismissed {
                inAppBrowser?.dismiss(animated: true, completion: nil)
            }
            inAppBrowser = nil
        }
    }
}
