import Foundation

class KeysFunction: ModuleFunction {
    private static let name = "keys"
    private let secureStorage: any SecureStorage

    init(module: Module, secureStorage: any SecureStorage) {
        self.secureStorage = secureStorage
        super.init(module: module, name: Self.name)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        secureStorage.getKeys { result in
            switch result {
            case .success(let keys):
                guard let json = toJson(keys) else {
                    jsCallback(Result.success("\(JsonContants.emptyArray)"))
                    return
                }
                jsCallback(Result.success("\(json)"))
            case .failure(let internalError):
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: internalError.localizedDescription)))
            }
        }
    }
}
