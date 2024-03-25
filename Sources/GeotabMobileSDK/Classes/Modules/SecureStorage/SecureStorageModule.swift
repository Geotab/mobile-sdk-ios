import Foundation

class SecureStorageModule: Module {
    private static let moduleName = "secureStorage"
    
    init() {
        super.init(name: Self.moduleName)
        functions.append(ClearFunction(module: self, secureStorage: SecureStorageRepository.shared))
        functions.append(GetItemFunction(module: self, secureStorage: SecureStorageRepository.shared))
        functions.append(KeysFunction(module: self, secureStorage: SecureStorageRepository.shared))
        functions.append(LengthFunction(module: self, secureStorage: SecureStorageRepository.shared))
        functions.append(RemoveItemFunction(module: self, secureStorage: SecureStorageRepository.shared))
        functions.append(SetItemFunction(module: self, secureStorage: SecureStorageRepository.shared))
    }
}
