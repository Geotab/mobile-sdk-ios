import Foundation

protocol ConnectivityStopping: Module {
    var started: Bool { get }
    func stop()
}

class StopFunction: ModuleFunction {
    private static let functionName: String = "stop"
    private weak var stopper: ConnectivityStopping?
    
    init(stopper: ConnectivityStopping) {
        self.stopper = stopper
        super.init(module: stopper, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        stop()
        jsCallback(Result.success("true"))
    }
    
    func stop() {
        stopper?.stop()
    }
}
