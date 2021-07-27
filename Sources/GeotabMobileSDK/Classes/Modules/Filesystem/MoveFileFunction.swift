// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation

struct MoveFileArgument: Codable {
    let srcPath: String
    let dstPath: String
    let overwrite: Bool?
}

class MoveFileFunction: ModuleFunction{
    
    private let module: FileSystemModule
    init(module: FileSystemModule) {
        self.module = module
        super.init(module: module, name: "moveFile")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.queue.async {
            guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let argData = try? JSONSerialization.data(withJSONObject: argument!) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            guard let arg = try? JSONDecoder().decode(MoveFileArgument.self, from: argData) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            let srcPath = arg.srcPath
            let destPath = arg.dstPath
            
            guard let drvfsDir = self.module.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemModule.DRVS_DOESNT_EXIST)))
                return
            }
            
            do {
                try moveFile(fsPrefix: FileSystemModule.fsPrefix, drvfsDir: drvfsDir, srcPath: srcPath, dstPath: destPath, overwrite: arg.overwrite ?? false)
                jsCallback(Result.success("undefined"))
            } catch {
                jsCallback(Result.failure(error))
                return
            }
        }
    }
}
