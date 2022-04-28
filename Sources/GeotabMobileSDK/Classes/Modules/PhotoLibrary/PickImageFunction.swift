import Foundation
import UIKit

struct PickImageFunctionArgument: Codable {
    let size: Size?
    let fileName: String?
}

class PickImageFunction: ModuleFunction {
    private let moduleContainer: ModuleContainerDelegate
    private let module: PhotoLibraryModule
    private var requests: [ImageFileControllerRequest] = []
    init(module: PhotoLibraryModule, moduleContainer: ModuleContainerDelegate) {
        self.module = module
        self.moduleContainer = moduleContainer
        super.init(module: module, name: "pickImage")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        var resizeTo: CGSize?
        var fileName = fileNameFromCurrentDate()
        if argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) {
            guard let arg = try? JSONDecoder().decode(PickImageFunctionArgument.self, from: data) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            if let size = arg.size {
                resizeTo = CGSize(width: size.width, height: size.height)
            }
            if let name = arg.fileName {
                fileName = name
            }
        }
        guard let fsMod = self.moduleContainer.findModule(module: "fileSystem") as? FileSystemModule, let drvfs = fsMod.drvfsDir else {
            jsCallback(Result.failure(GeotabDriveErrors.CaptureImageError(error: "Missing filesystem module")))
            return
        }
        do {
            let path = "\(FileSystemModule.fsPrefix)\(fileName).png"
            if try fileExist(fsPrefix: FileSystemModule.fsPrefix, drvfsDir: drvfs, path: path) {
                throw GeotabDriveErrors.FileException(error: "File already exist \(path)")
            }
            let request = ImageFileControllerRequest(viewPresenter: module.viewPresenter, sourceType: .photoLibrary, resizeTo: resizeTo) { request, result in
                self.requests.removeAll { $0 == request}
                switch result {
                case .success(let img):
                    guard let image = img, let png = image.pngData() else {
                        jsCallback(Result.failure(GeotabDriveErrors.CaptureImageError(error: "Pick Image Cancelled")))
                        return
                    }
                    do {
                        
                        let path = "\(FileSystemModule.fsPrefix)\(fileName).png"
                        _ = try writeFile(fsPrefix: FileSystemModule.fsPrefix, drvfsDir: drvfs, path: path, data: png, offset: 0)
                        jsCallback(Result.success("\"\(path)\""))
                    } catch {
                        jsCallback(Result.failure(error))
                    }
                case .failure(let error):
                    jsCallback(Result.failure(error))
                }
            }
            requests.append(request)
            request.captureImage()
        } catch {
            jsCallback(Result.failure(error))
        }

    }
}
