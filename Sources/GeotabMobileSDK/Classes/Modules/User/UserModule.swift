enum UserError: String {
    case jsEvalFailed = "Evaluation of JS failed."
    case noUsersReturned = "No users returned."
    case noAvailabilityReturned = "No DutyStatusAvailability returned."
    case noHosRuleSetReturned = "No HOSRuleSet returned."
    case noViolationsReturned = "No DutyStatusViolations returned."
}

class UserModule: Module {
    static let moduleName = "user"

    private weak var scriptGateway: ScriptGateway?
    var driverActionNecessaryCallback: DriverActionNecessaryCallbackType?
    var pageNavigationCallback: PageNavigationCallbackType?
    var loginRequiredCallback: LoginRequiredCallbackType?
    
    init(scriptGateway: ScriptGateway) {
        self.scriptGateway = scriptGateway
        super.init(name: UserModule.moduleName)
        functions.append(GetAllUsersFunction(module: self, scriptGateway: scriptGateway))
        functions.append(GetAvailabilityFunction(module: self, scriptGateway: scriptGateway))
        functions.append(GetViolationsFunction(module: self, scriptGateway: scriptGateway))
        functions.append(GetHosRuleSetFunction(module: self, scriptGateway: scriptGateway))
        functions.append(SetDriverSeatFunction(module: self, scriptGateway: scriptGateway))
        functions.append(DriverActionNecessaryFunction(module: self))
        functions.append(PageNavigationFunction(module: self))
        functions.append(LoginRequiredFunction(module: self))
    }
}
