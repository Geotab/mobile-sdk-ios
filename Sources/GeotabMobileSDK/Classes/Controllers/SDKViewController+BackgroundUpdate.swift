import Foundation

protocol BackgroundUpdating {
    func registerForBackgroundUpdates()
}

extension SDKViewController {
    public func registerForBackgroundUpdates() {
        for module in modules {
            if let backgroundUpdatingModule = module as? (any BackgroundUpdating) {
                backgroundUpdatingModule.registerForBackgroundUpdates()
            }
        }
    }
}
