import UIKit

class PhotoLibraryModule: Module {
    static let moduleName = "photoLibrary"

    let imageAccess: ImageAccessHelper
    let filesystemAccess: FilesystemAccessHelper

    init(viewPresenter: ViewPresenter, moduleContainer: ModuleContainer) {
        filesystemAccess = FilesystemAccessHelper(moduleContainer: moduleContainer)
        imageAccess = ImageAccessHelper(viewPresenter: viewPresenter, sourceType: .photoLibrary)
        super.init(name: PhotoLibraryModule.moduleName)
        functions.append(PickImageFunction(module: self,
                                           filesystem: filesystemAccess,
                                           imageAccessor: imageAccess))
    }
}
