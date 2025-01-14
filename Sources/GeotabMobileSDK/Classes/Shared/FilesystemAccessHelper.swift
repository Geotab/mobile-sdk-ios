import Foundation

class FilesystemAccessHelper: FilesystemAccessing {
    
    static let fsPrefix = "drvfs:///"
    
    static let drvfsDir: URL? = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.count > 0 ? paths[0].appendingPathComponent("drvfs", isDirectory: true) : nil
    }()

    func filesystemPrefix() -> String { Self.fsPrefix }

    func fileExists(path: String) throws -> Bool {
        guard let drvfsDir = Self.drvfsDir else {
            throw GeotabDriveErrors.CaptureImageError(error: "Missing filesystem module")
        }
        return try GeotabMobileSDK.fileExist(fsPrefix: Self.fsPrefix, drvfsDir: drvfsDir, path: path)
    }
    
    func writeFile(path: String, data: Data, offset: UInt64?) throws -> UInt64 {
        guard let drvfsDir = Self.drvfsDir else {
            throw GeotabDriveErrors.CaptureImageError(error: "Missing filesystem module")
        }
        return try GeotabMobileSDK.writeFile(fsPrefix: Self.fsPrefix, drvfsDir: drvfsDir, path: path, data: data, offset: 0)
    }
}
