class UserModule: Module {
    static let moduleName = "user"

    let scriptGateway: ScriptGateway
    var driverActionNecessaryCallback: DriverActionNecessaryCallbackType?
    var pageNavigationCallback: PageNavigationCallbackType?
    var loginRequiredCallback: LoginRequiredCallbackType?
    init(scriptGateway: ScriptGateway) {
        self.scriptGateway = scriptGateway
        super.init(name: UserModule.moduleName)
        functions.append(GetAllUsersFunction(module: self))
        functions.append(GetAvailabilityFunction(module: self))
        functions.append(GetViolationsFunction(module: self))
        functions.append(GetHosRuleSetFunction(module: self))
        functions.append(SetDriverSeatFunction(module: self))
        functions.append(DriverActionNecessaryFunction(module: self))
        functions.append(PageNavigationFunction(module: self))
        functions.append(LoginRequiredFunction(module: self))
    }
}
