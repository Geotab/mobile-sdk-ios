import Foundation

class ListFunction: ModuleFunction {
    
    private let module: FileSystemModule
    init(module: FileSystemModule) {
        self.module = module
        super.init(module: module, name: "list")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        module.queue.async {
            
            guard let filePath = argument as? String else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            guard let drvfsDir = self.module.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                let result = try listFile(fsPrefix: FileSystemModule.fsPrefix, drvfsDir: drvfsDir, path: filePath)
                jsCallback(Result.success(toJson(result)!))
            } catch {
                jsCallback(Result.failure(error))
            }
        }
        
    }
    
}
