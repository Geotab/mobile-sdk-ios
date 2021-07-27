// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation

func fileExist(fsPrefix: String, drvfsDir: URL, path: String) throws -> Bool {
    guard path.hasPrefix(FileSystemModule.fsPrefix) && !path.hasSuffix("/") else {
        throw GeotabDriveErrors.FileException(error: "Invalid file path")
    }

    let relativeFilePath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    let fm = FileManager.default
    
    let url = URL(fileURLWithPath: String(relativeFilePath), relativeTo: drvfsDir)
    
    return fm.fileExists(atPath: url.path)
}

func writeFile(fsPrefix: String, drvfsDir: URL, path: String, data: Data, offset: UInt64?) throws -> UInt64 {
    guard path.hasPrefix(FileSystemModule.fsPrefix) && !path.hasSuffix("/") else {
        throw GeotabDriveErrors.FileException(error: "Invalid file path")
    }

    let relativeFilePath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    var fileName = relativeFilePath
    if let idx = relativeFilePath.lastIndex(of: "/") {
        fileName = String(relativeFilePath[relativeFilePath.index(idx, offsetBy: 1)..<relativeFilePath.endIndex])
    }

    let relativeFolderPath = String(relativeFilePath.prefix(relativeFilePath.count - fileName.count))
    let folderUrl = URL(fileURLWithPath: relativeFolderPath, relativeTo: drvfsDir)
    
    guard folderUrl.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(path)")
    }
    
    let fm = FileManager.default
    
    if !fm.fileExists(atPath: folderUrl.path) {
        do {
            try fm.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw GeotabDriveErrors.FileException(error: "Failed creating directory \(relativeFolderPath)")
        }
    }
    
    
    let url = URL(fileURLWithPath: String(relativeFilePath), relativeTo: drvfsDir)
    
    if !fm.fileExists(atPath: url.path) {
        if fm.createFile(atPath: url.path, contents: nil, attributes: nil) != true {
            throw GeotabDriveErrors.FileException(error: "Failed creating file \(fileName)")
        }
    }
    
    guard let fileHandle = try? FileHandle(forWritingTo: url) else {
        throw GeotabDriveErrors.FileException(error: "Failed opening file for writing")
    }
    
    if let offset = offset {
        fileHandle.seek(toFileOffset: offset)
    } else {
        fileHandle.seekToEndOfFile()
    }
    fileHandle.write(data)
    fileHandle.seekToEndOfFile()
    let size = fileHandle.offsetInFile
    fileHandle.closeFile()
    return size
}

func readFile(fsPrefix: String, drvfsDir: URL, path: String, offset: UInt64, size: UInt64? = nil) throws -> Data {
    guard path.hasPrefix(FileSystemModule.fsPrefix) && !path.hasSuffix("/") else {
        throw GeotabDriveErrors.FileException(error: "Invalid file path \(path)")
    }
    
    let relativeFilePath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    let fm = FileManager.default
    let url = URL(fileURLWithPath: String(relativeFilePath), relativeTo: drvfsDir)
    
    guard url.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(path)")
    }
    
    if !fm.fileExists(atPath: url.path) {
        throw GeotabDriveErrors.FileException(error: "File doesn't exist \(path)")
    }
    
    guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
        throw GeotabDriveErrors.FileException(error: "Failed opening file for reading")
    }
    
    fileHandle.seek(toFileOffset: offset)
    
    let data: Data!
    if let sz = size {
        if sz > Int.max {
            throw GeotabDriveErrors.FileException(error: "Size parameter exceeded system limit")
        }
        data = fileHandle.readData(ofLength: Int(sz))
    } else {
        data = fileHandle.readDataToEndOfFile()
    }
    fileHandle.closeFile()
    return data
}

func readFileAsText(fsPrefix: String, drvfsDir: URL, path: String) throws -> String{
    guard path.hasPrefix(FileSystemModule.fsPrefix) && !path.hasSuffix("/") else {
        throw GeotabDriveErrors.FileException(error: "Invalid file path \(path)")
    }
    
    let relativeFilePath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    let fm = FileManager.default
    let url = URL(fileURLWithPath: String(relativeFilePath), relativeTo: drvfsDir)
    
    guard url.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(path)")
    }
    
    if !fm.fileExists(atPath: url.path) {
        throw GeotabDriveErrors.FileException(error: "File doesn't exist \(path)")
    }
    
    let content = try String(contentsOfFile: url.path, encoding: .utf8)
    let array = [content]
    
    do{
        let json: Data = try JSONSerialization.data(withJSONObject: array, options: [])
        var data: String = String(data: json, encoding: .utf8)!
        data = String(data.dropFirst().dropLast())
        return data
    }
    catch{
        throw GeotabDriveErrors.FileException(error: "Failed JSON to string conversion")
    }
}

func deleteFile(fsPrefix: String, drvfsDir: URL, path: String) throws -> Void{
    
    var resultStorage: ObjCBool = false
    
    guard path.hasPrefix(FileSystemModule.fsPrefix) && !path.hasSuffix("/") else {
        throw GeotabDriveErrors.FileException(error: "Invalid file path \(path)")
    }
    
    let relativeFilePath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    let fm = FileManager.default
    let url = URL(fileURLWithPath: String(relativeFilePath), relativeTo: drvfsDir)
    guard url.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(path)")
    }
    
    if !fm.fileExists(atPath: url.path, isDirectory: &resultStorage) {
        throw GeotabDriveErrors.FileException(error: "File doesn't exist \(path)")
    }
    
    let isDir = resultStorage.boolValue
    
    if(isDir){
        throw GeotabDriveErrors.FileException(error: "Given path is a directory")
    }
    
    do {
        try fm.removeItem(at: url)
    }
    catch{
        throw GeotabDriveErrors.FileException(error: "Failed deleting file")
    }

}

func getFileInfo(fsPrefix: String, drvfsDir: URL, path: String) throws -> FileInfo {
    var resultStorage: ObjCBool = false
    
    let dateFormatter = ISO8601DateFormatter()
    
    guard path.hasPrefix(FileSystemModule.fsPrefix) else {
        throw GeotabDriveErrors.FileException(error: "Invalid file path: \(path)")
    }
    
    let relativeFolderPath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    
    let fm = FileManager.default
    let url = URL(fileURLWithPath: String(relativeFolderPath), relativeTo: drvfsDir)
    
    guard url.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(path)")
    }
    
    var fileName = "" // default empty name if path is pointing to root folder
    if url.path != drvfsDir.path, let idx = url.path.lastIndex(of: "/") {
        fileName = String(url.path[url.path.index(idx, offsetBy: 1)..<url.path.endIndex])
    }
    
    if !fm.fileExists(atPath: url.path, isDirectory: &resultStorage) {
        throw GeotabDriveErrors.FileException(error: "File doesn't exist: \(path)")
    }
    let attr = try fm.attributesOfItem(atPath: "\(url.path)")
    guard let modifiedDate = attr[FileAttributeKey.modificationDate] as? Date,
          let size = attr[FileAttributeKey.size] as? UInt32 else {
        throw GeotabDriveErrors.FileException(error: "Unable to get file attributes: \(path)")
    }

    
    return FileInfo(name: fileName, size: resultStorage.boolValue ? nil:size, isDir: resultStorage.boolValue, modifiedDate: dateFormatter.string(from: modifiedDate))

}

func listFile(fsPrefix: String, drvfsDir: URL, path: String) throws -> [FileInfo] {
    
    var resultStorage: ObjCBool = false
    var result = [FileInfo]()
    
    let dateFormatter = ISO8601DateFormatter()
    
    guard path.hasPrefix(FileSystemModule.fsPrefix) else {
        throw GeotabDriveErrors.FileException(error: "Invalid directory path \(path)")
    }
    
    let relativeDirectoryPath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    let fm = FileManager.default
    
    if !fm.fileExists(atPath: drvfsDir.path) {
        do {
            try fm.createDirectory(at: drvfsDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw GeotabDriveErrors.FileException(error: "Failed initializing drvfs:/// directory")
        }
    }
    
    let url = URL(fileURLWithPath: String(relativeDirectoryPath), relativeTo: drvfsDir)
    
    guard url.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(path)")
    }
    
    if !fm.fileExists(atPath: url.path, isDirectory: &resultStorage) || !resultStorage.boolValue {
            throw GeotabDriveErrors.FileException(error: "Invalid directory path \(path)")
    }

    
    do {
        let items = try fm.contentsOfDirectory(atPath: url.path)
        
        for item in items {
            
            if fm.fileExists(atPath: "\(url.path)/\(item)", isDirectory: &resultStorage) {
                let attr = try fm.attributesOfItem(atPath: "\(url.path)/\(item)")
                guard let modifiedDate = attr[FileAttributeKey.modificationDate] as? Date else {
                    continue
                }
                guard let fileSize = attr[FileAttributeKey.size] as? UInt32 else {
                    continue
                }
                let fileInfo = FileInfo(name: item, size: resultStorage.boolValue ? nil:fileSize, isDir: resultStorage.boolValue, modifiedDate: dateFormatter.string(from: modifiedDate))
                result.append(fileInfo)
            }
        
        }
    } catch {
        throw GeotabDriveErrors.FileException(error: "Failed to load contents for directory at path \(path)")
    }
    
    return result
}

func deleteFolder(fsPrefix: String, drvfsDir: URL, path: String) throws -> Void{
    
    var resultStorage: ObjCBool = false
    
    guard path.hasPrefix(FileSystemModule.fsPrefix) else {
        throw GeotabDriveErrors.FileException(error: "Invalid folder path \(path)")
    }
    
    let relativeFilePath = path[ path.index(path.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<path.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    let fm = FileManager.default
    let url = URL(fileURLWithPath: String(relativeFilePath), relativeTo: drvfsDir)
    guard url.path != drvfsDir.path else {
        throw GeotabDriveErrors.FileException(error: "You can't delete the root folder: \(path)")
    }
    
    guard url.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(path)")
    }
    
    if !fm.fileExists(atPath: url.path, isDirectory: &resultStorage) {
        throw GeotabDriveErrors.FileException(error: "Folder doesn't exist: \(path)")
    }
    
    let isDir = resultStorage.boolValue
    
    if(!isDir){
        throw GeotabDriveErrors.FileException(error: "Given path is not a folder: \(path)")
    }
    
    var itemsCount = 0
    
    do {
        let items = try fm.contentsOfDirectory(atPath: url.path)
        itemsCount = items.count
    } catch {
        throw GeotabDriveErrors.FileException(error: "Failed checking folder content: \(path)")
    }
    
    guard itemsCount == 0 else {
        throw GeotabDriveErrors.FileException(error: "Folder is not empty: \(path)")
    }
    
    do {
        try fm.removeItem(at: url)
    }
    catch{
        throw GeotabDriveErrors.FileException(error: "Failed deleting folder: \(path)")
    }
}

func moveFile(fsPrefix: String, drvfsDir: URL, srcPath: String, dstPath: String, overwrite: Bool = false) throws -> Void {
    var resultStorage: ObjCBool = false
    
    guard srcPath.hasPrefix(FileSystemModule.fsPrefix) && !srcPath.hasSuffix("/") else {
        throw GeotabDriveErrors.FileException(error: "Invalid source path \(srcPath)")
    }
    
    guard dstPath.hasPrefix(FileSystemModule.fsPrefix) && !dstPath.hasSuffix("/") else {
        throw GeotabDriveErrors.FileException(error: "Invalid destination path \(dstPath)")
    }
    
    let relativeSrcPath = srcPath[ srcPath.index(srcPath.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<srcPath.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let relativeDestPath = dstPath[ dstPath.index(srcPath.startIndex, offsetBy: FileSystemModule.fsPrefix.count)..<dstPath.endIndex].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    
    let fm = FileManager.default
    let srcUrl = URL(fileURLWithPath: String(relativeSrcPath), relativeTo: drvfsDir)
    let destUrl = URL(fileURLWithPath: String(relativeDestPath), relativeTo: drvfsDir)
    
    guard srcUrl.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(srcPath)")
    }
    
    guard destUrl.path.hasPrefix(drvfsDir.path) else {
        throw GeotabDriveErrors.FileException(error: "Invalid path: \(dstPath)")
    }
    
    if !fm.fileExists(atPath: srcUrl.path, isDirectory: &resultStorage) {
        throw GeotabDriveErrors.FileException(error: "File doesn't exist \(srcPath)")
    }
    
    if !overwrite && fm.fileExists(atPath: destUrl.path) {
        throw GeotabDriveErrors.FileException(error: "File already exists at \(dstPath)")
    }
    
    let isDir = resultStorage.boolValue
    
    if(isDir){
        throw GeotabDriveErrors.FileException(error: "Given path is a directory")
    }
    
    if destUrl.path == srcUrl.path && overwrite {
        return
    }
    
    let relativeFolderPath = (relativeDestPath as NSString).deletingLastPathComponent
    let folderUrl = URL(fileURLWithPath: relativeFolderPath, relativeTo: drvfsDir)
    if !fm.fileExists(atPath: folderUrl.path) {
        do {
            try fm.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw GeotabDriveErrors.FileException(error: "Failed creating directory \(relativeFolderPath)")
        }
    }
    
    
    do {
        if (overwrite) {
            try fm.replaceItem(at: destUrl, withItemAt: srcUrl, backupItemName: nil, resultingItemURL: nil)
        } else {
            try fm.moveItem(at: srcUrl, to: destUrl)
        }
    }
    catch {
        throw GeotabDriveErrors.FileException(error: "Failed moving file")
    }
}

