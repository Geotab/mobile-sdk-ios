enum StateError: String {
    case noStateReturned = "No DeviceState returned."
}

class StateModule: Module {
    static let moduleName = "state"
    
    init(scriptGateway: any ScriptGateway) {
        super.init(name: StateModule.moduleName)
        functions.append(DeviceFunction(module: self, scriptGateway: scriptGateway))
    }
}
