import Foundation

class GetItemFunction: ModuleFunction {
    private static let name = "getItem"
    private let secureStorage: SecureStorage

    init(module: Module, secureStorage: SecureStorage) {
        self.secureStorage = secureStorage
        super.init(module: module, name: Self.name)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let key = jsonArgumentToString(argument) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        secureStorage.getItem(key) { result in
            switch result {
            case .success(let result):
                guard let stringResult = toJson(result) else {
                    jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: "Invalid result")))
                    return
                }
                jsCallback(Result.success(stringResult))
            case .failure(let internalError):
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: internalError.localizedDescription)))
            }
        }
    }
}
