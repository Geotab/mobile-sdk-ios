

class OnFunction: ModuleFunction {
    private let module: LocalNotificationModule
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: "on")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        guard let actionIdentifiers = argument as? [String] else {
            return
        }
        
        module.actionHandler = jsCallback
        module.actionIdentifiers = actionIdentifiers
    }
    
    override func scripts() -> String {
        
        let functionTemplate = try! Module.templateRepo.template(named: "ModuleFunction.On.Script")
        
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": module.name, "functionName": name]
        
        guard let functionScript = try? functionTemplate.render(scriptData) else {
            return ""
        }
        
        return functionScript
    }
}
