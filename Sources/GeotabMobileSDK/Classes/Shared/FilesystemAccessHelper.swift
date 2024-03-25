import Foundation

class FilesystemAccessHelper: FilesystemAccessing {
    let moduleContainer: ModuleContainer

    var drvfsDir: URL {
        get throws {
            guard let fsMod = self.moduleContainer.findModule(module: FileSystemModule.moduleName) as? FileSystemModule,
                  let drvfs = fsMod.drvfsDir else {
                throw GeotabDriveErrors.CaptureImageError(error: "Missing filesystem module")
            }
            return drvfs
        }
    }

    init(moduleContainer: ModuleContainer) {
        self.moduleContainer = moduleContainer
    }
    
    func filesystemPrefix() -> String {
        FileSystemModule.fsPrefix
    }

    func fileExists(path: String) throws -> Bool {
        try GeotabMobileSDK.fileExist(fsPrefix: filesystemPrefix(), drvfsDir: drvfsDir, path: path)
    }
    
    func writeFile(path: String, data: Data, offset: UInt64?) throws -> UInt64 {
        try GeotabMobileSDK.writeFile(fsPrefix: filesystemPrefix(), drvfsDir: drvfsDir, path: path, data: data, offset: 0)
    }
}
