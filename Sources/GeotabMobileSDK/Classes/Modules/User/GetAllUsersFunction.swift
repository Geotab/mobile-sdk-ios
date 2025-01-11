import WebKit

class GetAllUsersFunction: ModuleFunction {
    private static let functionName: String = "getAll"
    private weak var scriptGateway: ScriptGateway?
    var callbacks: [String: (Result<String, Error>) -> Void] = [:]
    init(module: UserModule, scriptGateway: ScriptGateway) {
        self.scriptGateway = scriptGateway
        super.init(module: module, name: Self.functionName)
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
        guard let users = arg.result else {
            callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: UserError.noUsersReturned.rawValue)))
            jsCallback(Result.failure(GeotabDriveErrors.JsIssuedError(error: UserError.noUsersReturned.rawValue)))
            callbacks[arg.callerId] = nil
            return
        }
        callback(Result.success(users))
        callbacks[arg.callerId] = nil
        jsCallback(Result.success("undefined"))
    }
    
    func call(_ callback: @escaping (Result<String, Error>) -> Void) {
        guard let scriptGateway else {
            callback(Result.failure(GeotabDriveErrors.InvalidObjectError))
            return
        }
        
        let callerId = UUID().uuidString
        self.callbacks[callerId] = callback
        
        let script = apiCallScript(templateRepo: Module.templateRepo, template: "ModuleFunction.GetAllUsersFunction.Api", scriptData: ["moduleName": moduleName, "functionName": name, "callerId": callerId])
        scriptGateway.evaluate(script: script) { [weak self] result in
            guard let self else { return }
            
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
