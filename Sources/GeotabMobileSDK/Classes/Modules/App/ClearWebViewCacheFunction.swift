import Foundation
import WebKit

class ClearWebViewCacheFunction: ModuleFunction {

    init(module: AppModule) {
        super.init(module: module, name: "clearWebViewCache")
    }

    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                modifiedSince: Date(timeIntervalSince1970: 0)) {
            jsCallback(Result.success("undefined"))
        }

    }
}
