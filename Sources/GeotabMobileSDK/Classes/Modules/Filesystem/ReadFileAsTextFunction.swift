import Foundation

// ReadFileAsText
struct ReadFileAsTextArgument: Codable {
    let path: String
}

class ReadFileAsTextFunction: ModuleFunction {
    private static let functionName: String = "readFileAsText"
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
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: ReadFileAsTextArgument.self) else { return }
            
            let path = arg.path
            
            guard let drvfsDir = FilesystemAccessHelper.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                let data = try readFileAsText(fsPrefix: FilesystemAccessHelper.fsPrefix, drvfsDir: drvfsDir, path: path)
                jsCallback(Result.success("\(data)"))
                
            } catch {
                jsCallback(Result.failure(error))
            }
            
        }
    }
}
