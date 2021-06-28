
//  DeleteFileFunction.swift
//  GeotabDriveSDK
//
//  Created by Anubhav Saini on 2020-09-29.
//

import Foundation


class DeleteFileFunction: ModuleFunction{
    
    private let module: FileSystemModule
    init(module: FileSystemModule) {
        self.module = module
        super.init(module: module, name: "deleteFile")
    }
    
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.queue.async {
            
            guard argument != nil else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            let filePath = argument as? String ?? ""
            
            guard let drvfsDir = self.module.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemModule.DRVS_DOESNT_EXIST)))
                return
            }
            
            do {
                try deleteFile(fsPrefix: FileSystemModule.fsPrefix, drvfsDir: drvfsDir, path: filePath)
                jsCallback(Result.success("undefined"))
            } catch {
                jsCallback(Result.failure(error))
            }
            
        }
    }
    
}
