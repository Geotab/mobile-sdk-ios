import UIKit

class KeepAwakeFunction: ModuleFunction {
    private static let functionName: String = "keepAwake"
    init(module: ScreenModule) {
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        guard let awake: Bool = argument as? Bool else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }

        UIApplication.shared.isIdleTimerDisabled = awake
        jsCallback(Result.success("\(awake)"))
    }
    
}
