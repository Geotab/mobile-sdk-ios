import Foundation

protocol LocationServiceStopping: Module {
    func stopService()
}

class StopLocationServiceFunction: ModuleFunction {
    static let functionName: String = "___stopLocationService"
    private weak var stopper: (any LocationServiceStopping)?
    init(stopper: any LocationServiceStopping) {
        self.stopper = stopper
        super.init(module: stopper, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        stopper?.stopService()
        jsCallback(Result.success("undefined"))
    }
}
