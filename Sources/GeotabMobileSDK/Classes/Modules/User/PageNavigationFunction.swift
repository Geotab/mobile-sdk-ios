//
//  PageNavigationFunction.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-03-30.
//
import Foundation

class PageNavigationFunction: ModuleFunction {
    private let module: UserModule
    init(module: UserModule) {
        self.module = module
        super.init(module: module, name: "pageNavigation")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard argument != nil, let path = argument as? String else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        DispatchQueue.main.async {
            self.module.pageNavigationCallback?(path)
        }
        jsCallback(Result.success("undefined"))
    }
}

