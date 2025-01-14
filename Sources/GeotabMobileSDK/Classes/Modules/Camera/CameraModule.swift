import UIKit

class CameraModule: Module {
    private static let moduleName = "camera"

    init(viewPresenter: ViewPresenter) {
        super.init(name: CameraModule.moduleName)
        functions.append(CaptureImageFunction(module: self,
                                              filesystem: FilesystemAccessHelper(),
                                              imageAccessor: ImageAccessHelper(viewPresenter: viewPresenter, sourceType: .camera)))
    }
}                         
