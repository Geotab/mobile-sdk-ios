//
//  StopFunction.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-02-19.
//

import Foundation

class StopFunction: ModuleFunction {
    private let module: ConnectivityModule
    
    init(module: ConnectivityModule) {
        self.module = module
        super.init(module: module, name: "stop")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        stop()
        jsCallback(Result.success("true"))
    }
    
    func stop() {
        module.reachability?.stopNotifier()
        module.started = false
    }
}
