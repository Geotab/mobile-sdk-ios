// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation

class StopIoxBleFunction: ModuleFunction {
    private let module: IoxBleModule
    init(module: IoxBleModule) {
        self.module = module
        super.init(module: module, name: "stop")
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async {
            self.module.stop()
            jsCallback(Result.success("undefined"))
        }
        
    }
}
