import Foundation

struct MoveFileArgument: Codable {
    let srcPath: String
    let dstPath: String
    let overwrite: Bool?
}

class MoveFileFunction: ModuleFunction {
    private static let functionName: String = "moveFile"
    private weak var queue: DispatchQueue?
    
    init(module: FileSystemModule) {
        queue = module.queue
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        guard let queue else {
            jsCallback(Result.failure(GeotabDriveErrors.InvalidObjectError))
            return
        }
        queue.async {
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: MoveFileArgument.self) else { return }
            
            let srcPath = arg.srcPath
            let destPath = arg.dstPath
            
            guard let drvfsDir = FilesystemAccessHelper.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                try moveFile(fsPrefix: FilesystemAccessHelper.fsPrefix, drvfsDir: drvfsDir, srcPath: srcPath, dstPath: destPath, overwrite: arg.overwrite ?? false)
                jsCallback(Result.success("undefined"))
            } catch {
                jsCallback(Result.failure(error))
                return
            }
        }
    }
}
