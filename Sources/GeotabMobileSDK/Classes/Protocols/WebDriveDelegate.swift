import WebKit

/**
 Interface for evaluating javascript script and pushing CustomEvent to WKWebview.
 */
internal protocol WebDriveDelegate: AnyObject {
    /**
     Evaluate a javascript code.
     
     - Parameters:
        - script: String. the script to be evaluated.
        - completed: The completion handler. Called when evaluation is done, succeeded or failed.
     */
    func evaluate(script: String, completed: @escaping (Result<Any?, Error>) -> Void)
    /**
     Push a HTML5 `CustomEvent` to WKWebview.
     */
    func push(moduleEvent: ModuleEvent, completed: @escaping (Result<Any?, Error>) -> Void)
    
    var webView: WKWebView { get }
}
