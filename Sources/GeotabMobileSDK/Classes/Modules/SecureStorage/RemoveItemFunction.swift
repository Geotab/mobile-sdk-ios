import Foundation

class RemoveItemFunction: ModuleFunction {
    private static let name = "removeItem"
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
    
        secureStorage.removeItem(key) { result in
            switch result {
            case .success:
                jsCallback(Result.success("\"\(key)\""))
            case .failure(let internalError):
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: internalError.localizedDescription)))
            }
        }
    }
}
