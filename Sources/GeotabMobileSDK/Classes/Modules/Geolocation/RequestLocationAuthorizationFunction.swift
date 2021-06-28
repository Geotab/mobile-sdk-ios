//
//  RequestLocationAuthorizationFunction.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-08-20.
//

import Foundation

class RequestLocationAuthorizationFunction: ModuleFunction {
    private let module: GeolocationModule
    init(module: GeolocationModule) {
        self.module = module
        super.init(module: module, name: "___requestLocationAuthorization")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.requestAuthorization()
        jsCallback(Result.success("undefined"))
    }
}
