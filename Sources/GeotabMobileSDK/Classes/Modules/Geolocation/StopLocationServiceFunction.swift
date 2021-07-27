// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation

class StopLocationServiceFunction: ModuleFunction {
    private let module: GeolocationModule
    init(module: GeolocationModule) {
        self.module = module
        super.init(module: module, name: "___stopLocationService")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.stopService()
        jsCallback(Result.success("undefined"))
    }
}
