enum DutyStatusLogError: String {
    case jsEvalFailed = "Evaluation of JS failed."
    case noDutyStatusLogReturned = "No DutyStatusLogs returned."
    case noCurrentDrivingLogsReturned = "No CurrentDrivingLogs returned."
}

class DutyStatusLogModule: Module {
    static let moduleName = "dutyStatusLog"

    private weak var scriptGateway: ScriptGateway?
    var driverActionNecessaryCallback: DriverActionNecessaryCallbackType?
    var pageNavigationCallback: PageNavigationCallbackType?
    var loginRequiredCallback: LoginRequiredCallbackType?
    
    init(scriptGateway: ScriptGateway) {
        self.scriptGateway = scriptGateway
        super.init(name: Self.moduleName)
        functions.append(GetDutyStatusLogFunction(module: self, scriptGateway: scriptGateway))
        functions.append(GetCurrentDrivingLogFunction(module: self, scriptGateway: scriptGateway))
    }
}
