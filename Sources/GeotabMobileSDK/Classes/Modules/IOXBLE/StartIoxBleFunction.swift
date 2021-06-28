//
//  StartIoxBleFunction.swift
//  GeotabMobileSDK
//
//  Created by Yunfeng Liu on 2021-02-11.
//

import Foundation

class StartIoxBleFunction: ModuleFunction {
    private let module: IoxBleModule
    init(module: IoxBleModule) {
        self.module = module
        super.init(module: module, name: "start")
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let uuid = argument as? String else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        DispatchQueue.main.async {
            self.module.start(serviceId: uuid, jsCallback)
        }
        
    }
}
