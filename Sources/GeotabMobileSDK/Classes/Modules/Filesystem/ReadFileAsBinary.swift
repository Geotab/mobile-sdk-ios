import Foundation

// ReadFileAsBinary
struct ReadFileAsBinaryArgument: Codable {
    let path: String // drvfs://sdsd/sdsd/fdd.txt
    let offset: UInt64? // offset is in Z+, not considering negative offset for now.
    let size: UInt64? // size is in Z+
}

class ReadFileAsBinaryFunction: ModuleFunction {
    private static let functionName: String = "readFileAsBinary"
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
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: ReadFileAsBinaryArgument.self) else { return }
            
            let path = arg.path
            
            guard let drvfsDir = FilesystemAccessHelper.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                let data = try readFile(fsPrefix: FilesystemAccessHelper.fsPrefix, drvfsDir: drvfsDir, path: path, offset: arg.offset ?? 0, size: arg.size)
                let uint8Array = [UInt8](data)
                let jsonData = try JSONSerialization.data(withJSONObject: uint8Array)
                let arrayJson = String(decoding: jsonData, as: UTF8.self)
                
                jsCallback(Result.success("new Uint8Array(\(arrayJson)).buffer"))
            } catch {
                jsCallback(Result.failure(error))
                return
            }
        }
    }
}
