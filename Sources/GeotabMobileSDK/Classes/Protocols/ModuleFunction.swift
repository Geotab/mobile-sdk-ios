//
//  ModuleFunction.swift
//  Drive
//
//  Created by Yunfeng Liu on 2019-10-28.
//
import Mustache
import WebKit
/**
 Module Function. This class is used for creating a Geotab Module function in the WKWebview/Javascript environment. Mostly intended for Drive and MyGeotab.
 */
open class ModuleFunction {
    private let _module: Module
    public let name: String
    /**
     - Parameters:
        - module: Module. The module this module function should reside in.
        - name: String. Name of the module in Javascript environment.
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
    open func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) -> Void {
        fatalError("Must Override")
    }
    
}

