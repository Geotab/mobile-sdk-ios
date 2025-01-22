import Foundation
import WebKit

class ClearWebViewCacheFunction: ModuleFunction {
    private static let functionName: String = "clearWebViewCache"
    init(module: AppModule) {
        super.init(module: module, name: Self.functionName)
    }

    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                modifiedSince: Date(timeIntervalSince1970: 0)) {
            jsCallback(Result.success("undefined"))
        }

    }
}
