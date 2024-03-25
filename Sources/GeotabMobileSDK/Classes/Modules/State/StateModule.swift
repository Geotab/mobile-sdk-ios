class StateModule: Module {
    static let moduleName = "state"

    let scriptGateway: ScriptGateway
    init(scriptGateway: ScriptGateway) {
        self.scriptGateway = scriptGateway
        super.init(name: StateModule.moduleName)
        functions.append(DeviceFunction(module: self))
    }
}
