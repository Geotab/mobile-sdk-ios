import WebKit

struct DriverActionNecessaryArgument: Codable {
    let isDriverActionNecessary: Bool
    let driverActionType: String
}

class DriverActionNecessaryFunction: ModuleFunction {
    private static let functionName: String = "driverActionNecessary"
    private weak var module: UserModule?
    init(module: UserModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let arg = validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: DriverActionNecessaryArgument.self) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.module?.driverActionNecessaryCallback?(arg.isDriverActionNecessary, arg.driverActionType)
        }
        jsCallback(Result.success("undefined"))
    }
}
