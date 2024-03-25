import Mustache
import WebKit
/**
 Defines a  function to be included in a Geotab module's Javascript API. Intended for internal Drive and MyGeotab use.
 */
open class ModuleFunction {
    private let _module: Module
    public let name: String
    /**
     - Parameters:
        - module: Module. The module this function should reside in.
        - name: String. Name of the Javascript function defined.
     */
    public init(module: Module, name: String) {
        self._module = module
        self.name = name
    }
    
    func apiCallScript(templateRepo: TemplateRepository, template: String, scriptData: [String: Any]) -> String {
        let apiCallTemplate = try? templateRepo.template(named: template)
        guard let script = try? apiCallTemplate?.render(scriptData) else {
            return ""
        }
        return script
    }
    
    func scripts() -> String {
        let functionTemplate = try! Module.templateRepo.template(named: "ModuleFunction.Script")
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": _module.name, "geotabNativeCallbacks": Module.geotabNativeCallbacks, "callbackPrefix": Module.callbackPrefix, "functionName": name]        
        guard let functionScript = try? functionTemplate.render(scriptData) else {
            return ""
        }
        return functionScript
    }
    
    open func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        fatalError("Must Override")
    }
    
}
