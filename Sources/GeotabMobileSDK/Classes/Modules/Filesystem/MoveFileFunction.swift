import Foundation

struct MoveFileArgument: Codable {
    let srcPath: String
    let dstPath: String
    let overwrite: Bool?
}

class MoveFileFunction: ModuleFunction {
    
    private let module: FileSystemModule
    init(module: FileSystemModule) {
        self.module = module
        super.init(module: module, name: "moveFile")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.queue.async {
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: MoveFileArgument.self) else { return }
            
            let srcPath = arg.srcPath
            let destPath = arg.dstPath
            
            guard let drvfsDir = self.module.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
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
