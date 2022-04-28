import WebKit

struct DriverActionNecessaryArgument: Codable {
    let isDriverActionNecessary: Bool
    let driverActionType: String
}

class DriverActionNecessaryFunction: ModuleFunction {
    private let module: UserModule
    init(module: UserModule) {
        self.module = module
        super.init(module: module, name: "driverActionNecessary")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        guard let arg = try? JSONDecoder().decode(DriverActionNecessaryArgument.self, from: data) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        DispatchQueue.main.async {
            self.module.driverActionNecessaryCallback?(arg.isDriverActionNecessary, arg.driverActionType)
        }
        jsCallback(Result.success("undefined"))
    }
}
