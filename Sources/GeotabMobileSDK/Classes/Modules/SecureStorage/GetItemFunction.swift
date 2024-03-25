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
                let escapedResult = result.replacingOccurrences(of: "\"", with: "\\\"")
                jsCallback(Result.success("\"\(escapedResult)\""))
            case .failure(let internalError):
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: internalError.localizedDescription)))
            }
        }
    }
}
