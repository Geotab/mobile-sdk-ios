import Foundation

class SetItemFunction: ModuleFunction {
    struct SetItemFunctionArgument: Codable {
        let key: String
        let value: String
    }

    private static let name = "setItem"

    private let secureStorage: any SecureStorage
    private let jsonArgumentDecoder: any JsonArgumentDecoding

    init(module: Module, 
         secureStorage: any SecureStorage,
         jsonArgumentDecoder: any JsonArgumentDecoding = JsonArgumentDecoder()) {
        self.secureStorage = secureStorage
        self.jsonArgumentDecoder = jsonArgumentDecoder
        super.init(module: module, name: Self.name)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {

        guard let data = jsonArgumentToData(argument),
              let arg = try? jsonArgumentDecoder.decode(SetItemFunctionArgument.self, from: data) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        secureStorage.setItem(arg.key, arg.value) { result in
            guard let stringKey = toJson(arg.key) else {
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: "Invalid key")))
                return
            }
            switch result {
            case .success:
                jsCallback(Result.success(stringKey))
            case .failure(let internalError):
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: internalError.localizedDescription)))
            }
        }
    }
}
