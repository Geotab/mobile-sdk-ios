import UIKit

struct ImageFunctionArgument: Codable {
    let size: Size?
    let fileName: String?
}

protocol FilesystemAccessing {
    func filesystemPrefix() -> String
    func fileExists(path: String) throws -> Bool
    func writeFile(path: String, data: Data, offset: UInt64?) throws -> UInt64
}

protocol ImageAccessing {
    func requestImage(resizeTo: CGSize?, completion: ((Result<UIImage?, Error>) -> Void)?)
}

class ImageFunctionHelper {
    private let filesystem: FilesystemAccessing
    private let imageAccessor: ImageAccessing
    private let jsonArgumentDecoder: JsonArgumentDecoding
    
    init(filesystem: FilesystemAccessing,
         imageAccessor: ImageAccessing,
         jsonArgumentDecoder: JsonArgumentDecoding = JsonArgumentDecoder()) {
        self.filesystem = filesystem
        self.imageAccessor = imageAccessor
        self.jsonArgumentDecoder = jsonArgumentDecoder
    }
    
    func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        var resizeTo: CGSize?
        var fileName = fileNameFromCurrentDate()
        let maxSize = 10000
        if let data = jsonArgumentToData(argument) {
            guard let arg = try? jsonArgumentDecoder.decode(ImageFunctionArgument.self, from: data) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            if let size = arg.size {
                if size.width <= 0 || size.width > maxSize || size.height <= 0 || size.height > maxSize {
                    jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                    return
                }
                resizeTo = CGSize(width: size.width, height: size.height)
            }
            if let name = arg.fileName {
                fileName = name
            }
        }
        let path = "\(filesystem.filesystemPrefix())\(fileName).png"
        do {
            if try filesystem.fileExists(path: path) {
                throw GeotabDriveErrors.FileException(error: "File already exist \(path)")
            }
        } catch {
            jsCallback(Result.failure(error))
            return
        }

        imageAccessor.requestImage(resizeTo: resizeTo) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let img):
                guard let image = img, let png = image.pngData() else {
                    jsCallback(Result.failure(GeotabDriveErrors.CaptureImageError(error: "Camera Cancelled")))
                    return
                }

                do {
                    _ = try self.filesystem.writeFile(path: path, data: png, offset: 0)
                    jsCallback(Result.success("\"\(path)\""))
                } catch {
                    jsCallback(Result.failure(error))
                }
            case .failure(let error):
                jsCallback(Result.failure(error))
            }
        }
    }
}
