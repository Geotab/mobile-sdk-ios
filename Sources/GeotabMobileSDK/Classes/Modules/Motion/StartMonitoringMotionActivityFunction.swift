//
//  StartMonitoringMotionActivityFunction.swift
//  GeotabMobileSDK
//
//  Created by Yunfeng Liu on 2021-01-28.
//

import Foundation

class StartMonitoringMotionActivityFunction: ModuleFunction {
    private let module: MotionModule
    init(module: MotionModule) {
        self.module = module
        super.init(module: module, name: "startMonitoringMotionActivity")
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        module.start(jsCallback)
    }
}
