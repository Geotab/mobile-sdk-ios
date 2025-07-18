import Foundation

class ClearFunction: ModuleFunction {
    private static let name = "clear"
    private let secureStorage: any SecureStorage
    
    init(module: Module, secureStorage: any SecureStorage) {
        self.secureStorage = secureStorage
        super.init(module: module, name: Self.name)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        secureStorage.deleteAll { result in
            switch result {
            case .success:
                jsCallback(Result.success(JsonContants.success))
            case .failure(let internalError):
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: internalError.localizedDescription)))
            }
        }
    }
}
