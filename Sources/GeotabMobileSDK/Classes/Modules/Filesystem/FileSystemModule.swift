import Foundation

class FileSystemModule: Module {
    static let DRVS_DOESNT_EXIST = "Drvfs filesystem doesn't exist."
    static let fsPrefix = "drvfs:///"
    let queue: DispatchQueue
    let drvfsDir: URL?
    init() {
        queue = DispatchQueue(label: "Filesystem Worker Queue")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        drvfsDir = paths.count > 0 ? paths[0].appendingPathComponent("drvfs", isDirectory: true) : nil
        
        super.init(name: "fileSystem")
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
