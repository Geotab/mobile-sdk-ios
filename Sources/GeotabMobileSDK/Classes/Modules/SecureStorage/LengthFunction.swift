import Foundation

class LengthFunction: ModuleFunction {
    private static let name = "length"
    private let secureStorage: any SecureStorage

    init(module: Module, secureStorage: any SecureStorage) {
        self.secureStorage = secureStorage
        super.init(module: module, name: Self.name)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        secureStorage.getLength { result in
            switch result {
            case .success(let length):
                guard let json = toJson(length) else {
                    jsCallback(Result.success(JsonContants.zero))
                    return
                }
                jsCallback(Result.success(json))
            case .failure(let internalError):
                jsCallback(Result.failure(GeotabDriveErrors.StorageModuleError(error: internalError.localizedDescription)))
            }
        }
    }
}
