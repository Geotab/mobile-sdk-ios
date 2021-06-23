//
//  GpsConnectedFunction.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-13.
//

import WebKit

struct GpsConnectedFunctionArgument: Codable {
    let callerId: String
    let error: String? // javascript given error, when js failed providing result, it provides error
    let result: GoDeviceState?
}

class GpsConnectedFunction: ModuleFunction {
    
    private let module: StateModule
    var callbacks: [String: CallbackWithType<Bool>] = [:]
    init(module: StateModule) {
        self.module = module
        super.init(module: module, name: "gpsConnected")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        guard let arg = try? JSONDecoder().decode(DeviceCommunicatingFunctionArgument.self, from: data) else {
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
        guard let state: GoDeviceState = arg.result else {
            callback(Result.failure(GeotabDriveErrors.JsIssuedError(error: "No DeviceState returned")))
            jsCallback(Result.failure(GeotabDriveErrors.JsIssuedError(error: "No DeviceState returned")))
            callbacks[arg.callerId] = nil
            return
        }
        callback(Result.success(state.gpsConnected))
        callbacks[arg.callerId] = nil
        jsCallback(Result.success("undefined"))
    }
    
    func call(_ callback: @escaping CallbackWithType<Bool>) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            guard let callback = self.callbacks[callerId] else {
                return
            }
            callback(Result.failure(GeotabDriveErrors.ApiCallTimeoutError))
            self.callbacks[callerId] = nil
        }
    }
    
}
