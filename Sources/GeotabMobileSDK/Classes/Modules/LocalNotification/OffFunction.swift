class OffFunction: ModuleFunction {
    private static let functionName: String = "off"
    private weak var module: LocalNotificationModule?
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {

        guard let module,
              let actionIdentifiers = argument as? [String] else {
            return
        }

        if module.actionHandler == nil {
            return
        }

        module.actionIdentifiers = actionIdentifiers
    }
    
    override func scripts() -> String {
        guard let module else { return "" }
        
        let functionTemplate = try! Module.templateRepo.template(named: "ModuleFunction.Off.Script")
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": module.name, "functionName": name]
        
        guard let functionScript = try? functionTemplate.render(scriptData) else {
            return ""
        }
        return functionScript
    }
}
