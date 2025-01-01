import SafariServices

protocol BrowserWindowOpening: Module {
    func openInExternalBrowser(url: URL)
    func openInAppBrowser(url: URL)
}

private enum HtmlTarget: String {
    case blank = "_blank"
    case `self` = "_self"
    case parent = "_parent"
    case top = "_top"
    case iab = "iab" // "iab" (in app browser) from Drive > login.ts > let win = openExternalUrl(redirectUrlWithTarget, "iab", { enableViewportScale: true });
    case system = "_system"
}

struct OpenBrowserWindowArguments: Codable {
    let url: String
    let target: String?
    let features: String? 
}

class OpenBrowserWindowFunction: ModuleFunction {
    private static let functionName: String = "openBrowserWindow"
    private weak var browserOpener: BrowserWindowOpening?
    init(browserOpener: BrowserWindowOpening) {
        self.browserOpener = browserOpener
        super.init(module: browserOpener, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async {
            
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: OpenBrowserWindowArguments.self) else { return }
            
            guard let urlString = arg.url as String?,
                let url = URL(string: urlString),
                let targetString: String = arg.target else {
                    jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                    return
            }
            
            let target = HtmlTarget(rawValue: targetString)
            switch target {
            case .blank, .system, .none:
                self.browserOpener?.openInExternalBrowser(url: url)
                
            case .parent, .top, .`self`, .iab:
                self.browserOpener?.openInAppBrowser(url: url)
            }
            
            jsCallback(Result.success("\"\(urlString)\""))
        }
    }
}
