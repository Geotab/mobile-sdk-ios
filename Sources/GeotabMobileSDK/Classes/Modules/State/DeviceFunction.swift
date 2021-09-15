

import WebKit


class DeviceFunction: ModuleFunction {
    private let module: StateModule
    var callbacks: [String: (Result<String, Error>) -> Void] = [:]
    init(module: StateModule) {
        self.module = module
        super.init(module: module, name: "device")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        guard let arg = try? JSONDecoder().decode(DriveApiFunctionArgument.self, from: data) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        guard let callback = callbacks[arg.callerId] else {
            jsCallback(Result.failure(GeotabDriveErrors.InvalidCallError))
            return
        }
        if let error = arg.error {
            callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: error)))
            jsCallback(Result.failure(GeotabDriveErrors.JsIssuedError(error: error)))
            callbacks[arg.callerId] = nil
            return
        }
        guard let state = arg.result else {
            callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: "No DeviceState returned")))
            jsCallback(Result.failure(GeotabDriveErrors.JsIssuedError(error: "No DeviceState returned")))
            callbacks[arg.callerId] = nil
            return
        }
        callback(Result.success(state))
        callbacks[arg.callerId] = nil
        jsCallback(Result.success("undefined"))
    }
    
    func call(_ callback: @escaping (Result<String, Error>) -> Void) {
        let callerId = UUID().uuidString
        self.callbacks[callerId] = callback
        
        let script = apiCallScript(templateRepo: Module.templateRepo, template: "ModuleFunction.DeviceState.Api", scriptData: ["moduleName": module.name, "functionName": name, "callerId": callerId])
        module.webDriveDelegate.evaluate(script: script) { result in
            switch result {
            case .success(_): return
            case .failure(_):
                if self.callbacks[callerId] == nil {
                    return
                }
                callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: "Evaluating JS failed")))
                self.callbacks[callerId] = nil
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DriveSdkConfig.apiCallTimeoutSeconds) {
            guard let callback = self.callbacks[callerId] else {
                return
            }
            callback(Result.failure(GeotabDriveErrors.ApiCallTimeoutError))
            self.callbacks[callerId] = nil
        }
    }
    
}
