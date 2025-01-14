import Foundation

class ListFunction: ModuleFunction {
    private static let functionName: String = "list"
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
            
            guard let filePath = argument as? String else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            guard let drvfsDir = FilesystemAccessHelper.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                let result = try listFile(fsPrefix: FilesystemAccessHelper.fsPrefix, drvfsDir: drvfsDir, path: filePath)
                jsCallback(Result.success(toJson(result)!))
            } catch {
                jsCallback(Result.failure(error))
            }
        }
        
    }
    
}
