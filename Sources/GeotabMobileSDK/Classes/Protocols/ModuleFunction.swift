import Mustache
import WebKit
/**
 Defines a  function to be included in a Geotab module's Javascript API. Intended for internal Drive and MyGeotab use.
 */
open class ModuleFunction {
    private let moduleName: String
    public let name: String
    /**
     - Parameters:
        - module: Module. The module this function should reside in.
        - name: String. Name of the Javascript function defined.
     */
    public init(module: Module, name: String) {
        moduleName = module.name
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
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": moduleName, "geotabNativeCallbacks": Module.geotabNativeCallbacks, "callbackPrefix": Module.callbackPrefix, "functionName": name]        
        guard let functionScript = try? functionTemplate.render(scriptData) else {
            return ""
        }
        return functionScript
    }
    
    func validateAndDecodeJSONObject<T>(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void, decodeType: T.Type) -> T? where T: Decodable {
        guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return nil
        }
        
        guard let arg = try? JSONDecoder().decode(decodeType.self, from: data) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return nil
        }
        return arg
    }
    
    open func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        fatalError("Must Override")
    }
    
}
