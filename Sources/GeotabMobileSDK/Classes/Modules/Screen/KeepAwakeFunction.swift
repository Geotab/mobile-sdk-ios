import UIKit

class KeepAwakeFunction: ModuleFunction {
    private let module: ScreenModule
    init(module: ScreenModule) {
        self.module = module
        super.init(module: module, name: "keepAwake")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let awake: Bool = argument as? Bool else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }

        UIApplication.shared.isIdleTimerDisabled = awake
        jsCallback(Result.success("\(awake)"))
    }
    
}
