import Foundation
import WebKit

extension MyGeotabViewController {

    public func setCustomURLPath(_ path: String) {
        pendingCustomPath = path
    }
    public func setLastServerAddressUpdatedCallback(_ callback: @escaping LastServerAddressUpdatedCallbackType) {
        guard let appModule = findModule(module: AppModule.moduleName) as? AppModule else { return }
        appModule.lastServerAddressUpdated = callback
    }

    public func clearLastServerAddressUpdatedCallback() {
        guard let appModule = findModule(module: AppModule.moduleName) as? AppModule else { return }
        appModule.lastServerAddressUpdated = nil
    }
}
