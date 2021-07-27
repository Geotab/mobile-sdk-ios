// Copyright © 2021 Geotab Inc. All rights reserved.

class OffFunction: ModuleFunction {
    private let module: LocalNotificationModule
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: "off")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {

        guard let actionIdentifiers = argument as? [String] else {
            return
        }

        if module.actionHandler == nil {
            return
        }

        module.actionIdentifiers = actionIdentifiers
    }
    
    override func scripts() -> String {
        
        let functionTemplate = try! Module.templateRepo.template(named: "ModuleFunction.Off.Script")
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": module.name, "functionName": name]
        
        guard let functionScript = try? functionTemplate.render(scriptData) else {
            return ""
        }
        return functionScript
    }
}
