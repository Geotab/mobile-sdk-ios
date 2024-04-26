import Foundation

// ReadFileAsText
struct ReadFileAsTextArgument: Codable {
    let path: String
}

class ReadFileAsTextFunction: ModuleFunction {
    private let module: FileSystemModule
    init(module: FileSystemModule) {
        self.module = module
        super.init(module: module, name: "readFileAsText")
    }
 
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.queue.async {
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: ReadFileAsTextArgument.self) else { return }
            
            let path = arg.path
            
            guard let drvfsDir = self.module.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
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
