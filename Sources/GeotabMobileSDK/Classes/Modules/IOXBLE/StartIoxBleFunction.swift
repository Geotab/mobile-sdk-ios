import Foundation

struct StartIoxBleArgument: Codable {
    let uuid: String?
    let reconnect: Bool?
}

class StartIoxBleFunction: ModuleFunction {
    private let module: IoxBleModule
    init(module: IoxBleModule) {
        self.module = module
        super.init(module: module, name: "start")
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let arg = validateAndDecodeJSONObject(argument: argument,
                                                    jsCallback: jsCallback,
                                                    decodeType: StartIoxBleArgument.self),
              let uuid = arg.uuid else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        DispatchQueue.main.async {
            self.module.start(serviceId: uuid, reconnect: arg.reconnect ?? false, jsCallback)
        }
        
    }
}
