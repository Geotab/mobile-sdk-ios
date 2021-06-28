//
//  AddonGetUser.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-03.
//

import WebKit
//import Mustache

struct GetUserFunctionArgument: Codable {
    let callerId: String
    let error: String? // javascript given error, when js failed providing result, it provides error
    let result: [User]?
}

class GetUserFunction: ModuleFunction {
    private let module: UserModule
    var callbacks: [String: CallbackWithType<User>] = [:]
    init(module: UserModule) {
        self.module = module
        super.init(module: module, name: "get")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        guard let arg = try? JSONDecoder().decode(GetUserFunctionArgument.self, from: data) else {
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
        guard let user = arg.result?.first else {
            callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: "No user returned")))
            jsCallback(Result.failure(GeotabDriveErrors.JsIssuedError(error: "No user returned")))
            callbacks[arg.callerId] = nil
            return
        }
        callback(Result.success(user))
        callbacks[arg.callerId] = nil
        jsCallback(Result.success("undefined"))
    }
    
    func call(_ callback: @escaping CallbackWithType<User>) {
        let callerId = UUID().uuidString
        self.callbacks[callerId] = callback
        
        let script = apiCallScript(templateRepo: Module.templateRepo, template: "ModuleFunction.GetUserFunction.Api", scriptData: ["moduleName": module.name, "functionName": name, "callerId": callerId])
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
