//
//  ReadFileAsTextFunction.swift
//  GeotabDriveSDK
//
//  Created by Satyaana Anton on 2020-07-20.
//

import Foundation

//ReadFileAsText
struct ReadFileAsTextArgument: Codable {
    let path: String
}

class ReadFileAsTextFunction: ModuleFunction {
    private let module: FileSystemModule
    init(module: FileSystemModule)  {
        self.module = module
        super.init(module: module, name: "readFileAsText")
    }
 
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void){
        module.queue.async{
            guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let argData = try? JSONSerialization.data(withJSONObject: argument!) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            guard let arg = try? JSONDecoder().decode(ReadFileAsTextArgument.self, from: argData) else{
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            let path = arg.path
            
            guard let drvfsDir = self.module.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemModule.DRVS_DOESNT_EXIST)))
                return
            }
           
            
            do {
                let data = try readFileAsText(fsPrefix: FileSystemModule.fsPrefix, drvfsDir: drvfsDir, path: path)
                jsCallback(Result.success("\(data)"))
                
            } catch {
                jsCallback(Result.failure(error))
            }
            
        }
    }
}
