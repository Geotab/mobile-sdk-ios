import Foundation

// ReadFileAsBinary
struct ReadFileAsBinaryArgument: Codable {
    let path: String // drvfs://sdsd/sdsd/fdd.txt
    let offset: UInt64? // offset is in Z+, not considering negative offset for now.
    let size: UInt64? // size is in Z+
}

class ReadFileAsBinaryFunction: ModuleFunction {
    private let module: FileSystemModule
    init(module: FileSystemModule) {
        self.module = module
        super.init(module: module, name: "readFileAsBinary")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        module.queue.async {
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: ReadFileAsBinaryArgument.self) else { return }
            
            let path = arg.path
            
            guard let drvfsDir = self.module.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                let data = try readFile(fsPrefix: FileSystemModule.fsPrefix, drvfsDir: drvfsDir, path: path, offset: arg.offset ?? 0, size: arg.size)
                let uint8Array = [UInt8](data)
                let jsonData = try JSONSerialization.data(withJSONObject: uint8Array)
                let arrayJson = String(data: jsonData, encoding: .utf8)! // unlikely to fail
                
                jsCallback(Result.success("new Uint8Array(\(arrayJson)).buffer"))
            } catch {
                jsCallback(Result.failure(error))
                return
            }
        }
    }
}
