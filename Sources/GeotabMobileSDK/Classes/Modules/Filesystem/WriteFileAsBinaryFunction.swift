import Foundation

struct WriteFileAsBinaryArgument: Codable {
    let path: String // drvfs://sdsd/sdsd/fdd.txt
    let data: [UInt8] // text data
    let offset: UInt64? // offset is in Z+, not considering negative offset for now.
}

class WriteFileAsBinaryFunction: ModuleFunction {
    private static let functionName: String = "writeFileAsBinary"
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
            guard let arg = self.validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: WriteFileAsBinaryArgument.self) else { return }
            
            let path = arg.path
            
            let data = Data(_: arg.data)
            
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
    override func scripts() -> String {
        let functionTemplate = try! Module.templateRepo.template(named: "ModuleFunction.WriteFileAsBinary.Script")
        
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": moduleName, "functionName": name, "geotabNativeCallbacks": Module.geotabNativeCallbacks, "callbackPrefix": Module.callbackPrefix]
        
        guard let functionScript = try? functionTemplate.render(scriptData) else {
            return ""
        }
        return functionScript
    }
}
