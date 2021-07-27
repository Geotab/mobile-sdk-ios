// Copyright © 2021 Geotab Inc. All rights reserved.

class UserModule: Module {
    let webDriveDelegate: WebDriveDelegate
    var driverActionNecessaryCallback: DriverActionNecessaryCallbackType?
    var pageNavigationCallback: PageNavigationCallbackType?
    var loginRequiredCallback: LoginRequiredCallbackType?
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        super.init(name: "user")
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
