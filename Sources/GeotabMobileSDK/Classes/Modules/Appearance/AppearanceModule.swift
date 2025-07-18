public import UIKit

protocol AppearanceSource: AnyObject {
    var appearanceType: AppearanceType { get }
}

class AppearanceModule: Module {
    static let moduleName = "appearance"
    static let eventName = "geotab.appearance"
    static let appearanceProperty = "appearanceType"

    private weak var scriptGateway: (any ScriptGateway)?
    private weak var appearanceSource: (any AppearanceSource)?

    init(scriptGateway: any ScriptGateway, appearanceSource: any AppearanceSource) {
        self.scriptGateway = scriptGateway
        self.appearanceSource = appearanceSource
        super.init(name: AppearanceModule.moduleName)
    }
    
    func appearanceChanged() {
        scriptGateway?.evaluate(script: updateAppearancePropertyScript()) { _ in }        
        let event = ModuleEvent(event: AppearanceModule.eventName,
                                params: appearanceEventDetailJson())
        scriptGateway?.push(moduleEvent: event) { _ in }
    }
    
    func appearanceType() -> AppearanceType {
        guard let appearance = appearanceSource?.appearanceType else {
            return .unknown
        }
        return appearance
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        scripts += updateAppearancePropertyScript()
        return scripts
    }
    
    private func updateAppearancePropertyScript() -> String {
        return """
        window.\(Module.geotabModules).\(name).\(AppearanceModule.appearanceProperty) = \(appearanceType().rawValue);
        """
    }

    private func appearanceEventDetailJson() -> String {
        return """
        { "detail": { "\(AppearanceModule.appearanceProperty)": \(appearanceType().rawValue) } }
        """
    }
}

// MARK: - DriveViewController extension implements AppearanceSource

/// :nodoc:
extension DriveViewController: AppearanceSource {
    
    var appearanceType: AppearanceType {
        return traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Only update if not backgrounded and the appearance changes. iOS may call this when
        // the app is backgrounded to take screen shots for the task switch. Our UI won't update
        // fast enough for that to work, so best to ignore in that case and avoid flicker
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)
            && UIApplication.shared.applicationState != .background {
            if let appearanceModule = findModule(module: AppearanceModule.moduleName) as? AppearanceModule {
                appearanceModule.appearanceChanged()
            }
        }
    }
}
