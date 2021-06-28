//
//  StopMonitoringMotionActivityFunction.swift
//  GeotabMobileSDK
//
//  Created by Yunfeng Liu on 2021-01-28.
//

import Foundation

class StopMonitoringMotionActivityFunction: ModuleFunction {
    private let module: MotionModule
    init(module: MotionModule) {
        self.module = module
        super.init(module: module, name: "stopMonitoringMotionActivity")
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.stop()
        jsCallback(Result.success("undefined"))
    }
}
