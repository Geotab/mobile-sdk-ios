import Foundation

class PageNavigationFunction: ModuleFunction {
    private static let functionName: String = "pageNavigation"
    private weak var module: UserModule?
    init(module: UserModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard argument != nil, let path = argument as? String else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.module?.pageNavigationCallback?(path)
        }
        jsCallback(Result.success("undefined"))
    }
}
