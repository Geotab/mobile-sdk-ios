import Foundation

enum FileSystemError: String {
    case fileSystemDoesNotExist = "drvfs filesystem doesn't exist."
}

class FileSystemModule: Module {
    static let moduleName = "fileSystem"
    
    static let fsPrefix = "drvfs:///"
    let queue: DispatchQueue
    let drvfsDir: URL?
    init() {
        queue = DispatchQueue(label: "Filesystem Worker Queue")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        drvfsDir = paths.count > 0 ? paths[0].appendingPathComponent("drvfs", isDirectory: true) : nil
        
        super.init(name: FileSystemModule.moduleName)
        functions.append(WriteFileAsTextFunction(module: self))
        functions.append(WriteFileAsBinaryFunction(module: self))
        functions.append(ReadFileAsTextFunction(module: self))
        functions.append(ReadFileAsBinaryFunction(module: self))
        functions.append(DeleteFileFunction(module: self))
        functions.append(ListFunction(module: self))
        functions.append(GetFileInfoFunction(module: self))
        functions.append(DeleteFolderFunction(module: self))
        functions.append(MoveFileFunction(module: self))
    }
}
