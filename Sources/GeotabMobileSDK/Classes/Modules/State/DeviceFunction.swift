import WebKit

class DeviceFunction: ModuleFunction {
    private let module: StateModule
    var callbacks: [String: (Result<String, Error>) -> Void] = [:]
    init(module: StateModule) {
        self.module = module
        super.init(module: module, name: "device")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let arg = validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: DriveApiFunctionArgument.self) else { return }
        
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
            callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: StateError.noStateReturned.rawValue)))
            jsCallback(Result.failure(GeotabDriveErrors.JsIssuedError(error: StateError.noStateReturned.rawValue)))
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
        module.scriptGateway.evaluate(script: script) { result in
            switch result {
            case .success: return
            case .failure:
                if self.callbacks[callerId] == nil {
                    return
                }
                callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: UserError.jsEvalFailed.rawValue)))
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
