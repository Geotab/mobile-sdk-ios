import Foundation

class DeleteFileFunction: ModuleFunction {
    
    private static let functionName: String = "deleteFile"

    private weak var queue: DispatchQueue?
    init(module: FileSystemModule) {
        queue = module.queue
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard let queue else {
            jsCallback(Result.failure(GeotabDriveErrors.InvalidObjectError))
            return
        }
        
        queue.async {
            
            guard argument != nil else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            let filePath = argument as? String ?? ""
            
            guard let drvfsDir = FilesystemAccessHelper.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                try deleteFile(fsPrefix: FilesystemAccessHelper.fsPrefix, drvfsDir: drvfsDir, path: filePath)
                jsCallback(Result.success("undefined"))
            } catch {
                jsCallback(Result.failure(error))
            }
            
        }
    }
    
}
