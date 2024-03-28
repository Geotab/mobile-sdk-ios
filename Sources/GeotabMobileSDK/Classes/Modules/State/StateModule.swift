enum StateError: String {
    case noStateReturned = "No DeviceState returned."
}

class StateModule: Module {
    static let moduleName = "state"

    let scriptGateway: ScriptGateway
    init(scriptGateway: ScriptGateway) {
        self.scriptGateway = scriptGateway
        super.init(name: StateModule.moduleName)
        functions.append(DeviceFunction(module: self))
    }
}
