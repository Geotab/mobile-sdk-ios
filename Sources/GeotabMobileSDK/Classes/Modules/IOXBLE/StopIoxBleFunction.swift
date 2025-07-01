import Foundation

class StopIoxBleFunction: ModuleFunction {
    private static let functionName: String = "stop"
    private weak var module: IoxBleModule?
    init(module: IoxBleModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.module?.stop()
            jsCallback(Result.success("undefined"))
        }
        
    }
}
