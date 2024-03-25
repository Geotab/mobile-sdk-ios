import UIKit

class CameraModule: Module {
    static let moduleName = "camera"

    let imageAccess: ImageAccessHelper
    let filesystemAccess: FilesystemAccessHelper

    init(viewPresenter: ViewPresenter, moduleContainer: ModuleContainer) {
        filesystemAccess = FilesystemAccessHelper(moduleContainer: moduleContainer)
        imageAccess = ImageAccessHelper(viewPresenter: viewPresenter, sourceType: .camera)
        super.init(name: CameraModule.moduleName)
        functions.append(CaptureImageFunction(module: self,
                                              filesystem: filesystemAccess,
                                              imageAccessor: imageAccess))
    }
}                         
