import SafariServices

protocol BrowserWindowClosing: Module {
    func closeInAppBrowser()
}

class CloseBrowserWindowFunction: ModuleFunction {
    private static let functionName: String = "closeBrowserWindow"
    private weak var browserCloser: BrowserWindowClosing?
    init(browserCloser: BrowserWindowClosing) {
        self.browserCloser = browserCloser
        super.init(module: browserCloser, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async {
            self.browserCloser?.closeInAppBrowser()
            
            jsCallback(Result.success("undefined"))
        }
    }
}
