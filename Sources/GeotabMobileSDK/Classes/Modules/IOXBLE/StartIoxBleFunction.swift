import Foundation

struct StartIoxBleArgument: Codable {
    let uuid: String?
    let reconnect: Bool?
}

class StartIoxBleFunction: ModuleFunction {
    private static let functionName: String = "start"
    private weak var module: IoxBleModule?
    init(module: IoxBleModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        guard let arg = validateAndDecodeJSONObject(argument: argument,
                                                    jsCallback: jsCallback,
                                                    decodeType: StartIoxBleArgument.self) else { return }
              
        guard let uuid = arg.uuid else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.module?.start(serviceId: uuid, reconnect: arg.reconnect ?? false, jsCallback)
        }
        
    }
}
