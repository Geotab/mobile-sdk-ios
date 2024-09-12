import Foundation

extension DriveViewController {
    /**
     Indicates whether the device is in charging state.
     */
    public var isCharging: Bool {
        guard let batteryModule = findModule(module: BatteryModule.moduleName) as? BatteryModule else {
            $logger.info("Could not find battery module")
            return false
        }
        return batteryModule.isCharging
    }
    
    /**
     Cancels a login request. When a user selects Add CoDriver in Drive, but does not to proceed to login, this function must be called. This function will navigate Drive to the most recent non-login page. If the login request is for a main driver , calling this function will  dismiss the DriveViewController.
     */
    public func cancelLogin() {
        if let fragment = webView.backForwardList.currentItem?.url.fragment, !fragment.contains("login") {
            return
        }
        for (_, itm) in webView.backForwardList.backList.enumerated().reversed() {
            if let fragment = itm.url.fragment, !fragment.lowercased().contains("login") {
                webView.go(to: itm)
                return
            }
            
        }
        dismiss(animated: true)
    }

    /**
     Get all driver users signed in.
     
     - Parameters:
        - callback: Result is given as a JSON string representing an array of Users
     */
    public func getAllUsers(_ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: UserModule.moduleName, function: "getAll") as? GetAllUsersFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(callback)
    }
    
    /**
    Get the HOS Rule Set.
     
     - Parameters:
        - callback: Result is given as a JSON string representing a HosRuleset
     */
    public func getHosRuleSet(userName: String, _ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: UserModule.moduleName, function: "getHosRuleSet") as? GetHosRuleSetFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.userName = userName
        fun.call(callback)
    }
    
    /**
    Get the User Availability.
     
     - Parameters:
        - callback: Result is given as a JSON string representing a DutyStatusAvailability
     */
    public func getUserAvailability(userName: String, _ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: UserModule.moduleName, function: "getAvailability") as? GetAvailabilityFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.userName = userName
        fun.call(callback)
    }
    
    /**
    Get the User Violations.
     
     - Parameters:
        - callback: Result is given as a JSON string representing a DutyStatusViolation
     */
    public func getUserViolations(userName: String, _ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: UserModule.moduleName, function: "getViolations") as? GetViolationsFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.userName = userName
        fun.call(callback)
    }
    
    /**
    Set a driver in driver seat.
     
     - Parameters:
        - driverId: String
        - callback: Result is given as a JSON string representing a User
     */
    public func setDriverSeat(driverId: String, _ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: UserModule.moduleName, function: "setDriverSeat") as? SetDriverSeatFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(driverId: driverId, callback)
    }
    
    /**
    Get the `Go Device` of Drive's `state`.
     
     - Parameters:
        - callback: Result is given as a JSON string representation of a GoDevice
     */
    public func getStateDevice(_ callback: @escaping (_ result: Result<String, Error>) -> Void) {
        guard let fun = findModuleFunction(module: StateModule.moduleName, function: "device") as? DeviceFunction else {
            callback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        fun.call(callback)
    }

    /**
    Set a custom speech Engine to replace the default one comes with the SDK.
     
     - Parameters:
        - speechEngine: `SpeechEngine`
     */
    public func setSpeechEngine(speechEngine: SpeechEngine) {
        guard let speechModule = findModule(module: SpeechModule.moduleName) as? SpeechModule else {
            return
        }
        speechModule.setSpeechEngine(speechEngine: speechEngine)
    }
    
    /**
    Set a new Geotab session for driver or co-driver. Setting a new session means adding a new driver to Drive. In case the given session is invalid, `Login Required` event will be triggered. See `setLoginRequiredCallback` for more detail.
     
     - Parameters:
        - credentialResult: `CredentialResult`.
        - isCoDriver: Bool. Indicate if its' for a co-driver login.
     */
    public func setSession(credentialResult: CredentialResult, isCoDriver: Bool = false) {
        loginCredentials = credentialResult
        var urlString = "https://\(DriveSdkConfig.serverAddress)/drive/default.html#ui/login,(server:'\(credentialResult.path)',credentials:(database:'\(credentialResult.credentials.database)',sessionId:'\(credentialResult.credentials.sessionId)',userName:'\(credentialResult.credentials.userName)'))"
        if isCoDriver {
            urlString = "https://\(DriveSdkConfig.serverAddress)/drive/default.html#ui/login,(addCoDriver:!t,server:'\(credentialResult.path)',credentials:(database:'\(credentialResult.credentials.database)',sessionId:'\(credentialResult.credentials.sessionId)',userName:'\(credentialResult.credentials.userName)'))"
        }
        if isViewLoaded, let url = URL(string: urlString) {
            webViewNavigationFailedView.reloadURL = url
            webView.load(URLRequest(url: url))
        }
    }
    
    /**
     Set navigation path. "path" will be concatenated as follows: "https://<my.geotab.com>/drive/default.html?#${path}".
     Once set, DriveViewController will navigate to the given UI path.
      
      This function can be used to implement iOS custom URL. For example by accepting "myscheme://dvir/main" as a launch URL, An app could navgate the app the requested path "dvir/main" on launch.
     
     - Parameters:
        - path: Drive's UI path to navigate to.
     */
    public func setCustomURLPath(path: String) {
        let urlString = "https://\(DriveSdkConfig.serverAddress)/drive/default.html#\(path)"
        if let url = URL(string: urlString) {
            customUrl = url
            if isViewLoaded,
               let url = webView.url?.with(fragment: path) {
                customUrl = nil
                if !path.isEmpty {
                    webView.load(URLRequest(url: url))
                }
            }
        }
    }
    
    /**
    Set `DriverActionNecessary` callback to listen for such event sent from Web Drive.
     
     - Parameters:
        - callback: `DriverActionNecessaryCallbackType`
     */
    public func setDriverActionNecessaryCallback(_ callback: @escaping DriverActionNecessaryCallbackType) {
        guard let userModule = findModule(module: UserModule.moduleName) as? UserModule else {
            return
        }
        userModule.driverActionNecessaryCallback = callback
    }
    
    /**
    Clear `DriverActionNecessary` callback listener.
     */
    public func clearDriverActionNecessaryCallback() {
        guard let userModule = findModule(module: UserModule.moduleName) as? UserModule else {
            return
        }
        userModule.driverActionNecessaryCallback = nil
    }
    
    /**
    Set `PageNavigation` callback listener.
     
     - Parameters:
        - callback: `PageNavigationCallbackType`
     */
    public func setPageNavigationCallback(_ callback: @escaping PageNavigationCallbackType) {
        guard let userModule = findModule(module: UserModule.moduleName) as? UserModule else {
            return
        }
        userModule.pageNavigationCallback = callback
    }
    
    /**
    Clear `PageNavigation` callback listener.
     */
    public func clearPageNavigationCallback() {
        guard let userModule = findModule(module: UserModule.moduleName) as? UserModule else {
            return
        }
        userModule.pageNavigationCallback = nil
    }
    
    /**
     Set a callback to listen for session changes. That includes: no session, invalid session, session expired, co-driver login is requested.
     
     - Parameters:
        - callback: `LoginRequiredCallbackType`
                - status: `""` `"LoginRequired"`, `"AddCoDriver"`.
                - errorMessage: Error happened during login process and error info is given in `errorMessage`.
     
     There are three defined values and variance of different error messages that could be passed in the callback.

     - "", empty string, indicates no login required or login is successful, or the login is in progress. At this state, implementor should presents the DriveViewController/Fragment.
     - "LoginRequired": indicates the login UI is going to show a login form(No valid user is available or the current activeSession is expired/invalid). At this state, implementor presents its own login screen.
     - "AddCoDriver": indicates that a co-driver login is requested. At this state, implementor presents its own co-driver login screen.
     - Any error message, any other error messages. At this state, implementor presents its own login screen.

     After receiving such session expired callback call. Integrator usually dismisses the presented `DriveViewController` and present user with its Login screen.

     */
    public func setLoginRequiredCallback(_ callback: @escaping LoginRequiredCallbackType) {
        guard let userModule = findModule(module: UserModule.moduleName) as? UserModule else {
            return
        }
        userModule.loginRequiredCallback = callback
    }
    
    /**
    Clear `LoginRequired` callback listener.
     */
    public func clearLoginRequiredCallback() {
        guard let userModule = findModule(module: UserModule.moduleName) as? UserModule else {
            return
        }
        userModule.loginRequiredCallback = nil
    }
    
    /**
    Set `LastServerAddressUpdated` callback listener. Such event is sent by Drive to notify impelementor that a designated "server address" should be used for future launches. Implementor should save the new server address in persistent storage. In the future launches, app should set the DriveSdkConfig.serverAddress with the stored new address before creating an instance of DriveViewController. Note such address is not the same as the counterparty one in MyGeotabViewController.
     
     - Parameters:
        - callback: `LastServerAddressUpdatedCallbackType`
     */
    public func setLastServerAddressUpdatedCallback(_ callback: @escaping LastServerAddressUpdatedCallbackType) {
        guard let appModule = findModule(module: AppModule.moduleName) as? AppModule else {
            return
        }
        appModule.lastServerAddressUpdated = callback
    }
    
    /**
    Clear `LastServerAddressUpdated` callback listener.
     */
    public func clearLastServerAddressUpdatedCallback() {
        guard let appModule = findModule(module: AppModule.moduleName) as? AppModule else {
            return
        }
        appModule.lastServerAddressUpdated = nil
    }
        
    /// :nodoc:
    public func setIOXDeviceEventCallback(_ callback: @escaping IOXDeviceEventCallbackType) {
        guard let ioxBleModule = findModule(module: IoxBleModule.moduleName) as? IoxBleModule else {
            return
        }
        ioxBleModule.ioxDeviceEventCallback = callback
    }
}

extension URL {
    func with(fragment: String) -> URL? {
        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true)
        urlComponents?.fragment = fragment.removingPercentEncoding
        return urlComponents?.url
    }
}
