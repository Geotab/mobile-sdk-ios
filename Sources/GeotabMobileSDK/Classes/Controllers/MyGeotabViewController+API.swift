import Foundation

extension MyGeotabViewController {
    public func setLastServerAddressUpdatedCallback(_ callback: @escaping LastServerAddressUpdatedCallbackType) {
        guard let appModule = findModule(module: AppModule.moduleName) as? AppModule else { return }
        appModule.lastServerAddressUpdated = callback
    }

    public func clearLastServerAddressUpdatedCallback() {
        guard let appModule = findModule(module: AppModule.moduleName) as? AppModule else { return }
        appModule.lastServerAddressUpdated = nil
    }
}
