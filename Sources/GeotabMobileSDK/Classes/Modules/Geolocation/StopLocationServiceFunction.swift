import Foundation

protocol LocationServiceStopping: Module {
    func stopService()
}

class StopLocationServiceFunction: ModuleFunction {
    private weak var stopper: LocationServiceStopping?
    init(stopper: LocationServiceStopping) {
        self.stopper = stopper
        super.init(module: stopper, name: "___stopLocationService")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        stopper?.stopService()
        jsCallback(Result.success("undefined"))
    }
}
