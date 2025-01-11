import WebKit

class GetViolationsFunction: ModuleFunction {
    private static let functionName: String = "getViolations"
    
    private weak var scriptGateway: ScriptGateway?
    var userName = ""
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
        guard let result = arg.result else {
            callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: UserError.noViolationsReturned.rawValue)))
            jsCallback(Result.failure(GeotabDriveErrors.JsIssuedError(error: UserError.noViolationsReturned.rawValue)))
            callbacks[arg.callerId] = nil
            return
        }
        callback(Result.success(result))
        callbacks[arg.callerId] = nil
        jsCallback(Result.success("undefined"))
    }
    
    func call(_ callback: @escaping (Result<String, Error>) -> Void) {
        let callerId = UUID().uuidString
        self.callbacks[callerId] = callback
        
        let script = apiCallScript(templateRepo: Module.templateRepo, template: "ModuleFunction.GetViolationsFunction.Api", scriptData: ["moduleName": moduleName, "functionName": name, "callerId": callerId, "userName": userName])
        scriptGateway?.evaluate(script: script) { [weak self] result in
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
        DispatchQueue.main.asyncAfter(deadline: .now() + DriveSdkConfig.apiCallTimeoutSeconds) { [weak self] in
            guard let self,
                  let callback = self.callbacks[callerId] else {
                return
            }
            callback(Result.failure(GeotabDriveErrors.ApiCallTimeoutError))
            self.callbacks[callerId] = nil
        }
    }
}
