//
//  UserModule.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-11.
//

class UserModule: Module {
    let webDriveDelegate: WebDriveDelegate
    var driverActionNecessaryCallback: DriverActionNecessaryCallbackType?
    var pageNavigationCallback: PageNavigationCallbackType?
    var loginRequiredCallback: LoginRequiredCallbackType?
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        super.init(name: "user")
        functions.append(GetAllUsersFunction(module: self))
        functions.append(GetUserFunction(module: self))
        functions.append(GetAvailabilityFunction(module: self))
        functions.append(GetViolationsFunction(module: self))
        functions.append(GetHosRuleSetFunction(module: self))
        functions.append(SetDriverSeatFunction(module: self))
        functions.append(DriverActionNecessaryFunction(module: self))
        functions.append(PageNavigationFunction(module: self))
        functions.append(LoginRequiredFunction(module: self))
    }
}
