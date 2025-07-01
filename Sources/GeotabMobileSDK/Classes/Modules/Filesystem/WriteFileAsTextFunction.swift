import Foundation

struct WriteFileAsTextArgument: Codable {
    let path: String // drvfs://sdsd/sdsd/fdd.txt
    let data: String // text data
    let offset: UInt64? // offset is in Z+, not considering negative offset for now.
}

class WriteFileAsTextFunction: ModuleFunction {
    private static let functionName: String = "writeFileAsText"
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
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: WriteFileAsTextArgument.self) else { return }
            
            let path = arg.path
            
            guard let data = arg.data.data(using: .utf8) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            
            guard let drvfsDir = FilesystemAccessHelper.drvfsDir else {
                jsCallback(Result.failure(GeotabDriveErrors.FileException(error: FileSystemError.fileSystemDoesNotExist.rawValue)))
                return
            }
            
            do {
                let size = try writeFile(fsPrefix: FilesystemAccessHelper.fsPrefix, drvfsDir: drvfsDir, path: path, data: data, offset: arg.offset)
                jsCallback(Result.success("\(size)"))
            } catch {
                jsCallback(Result.failure(error))
                return
            }
        }
    }
}
