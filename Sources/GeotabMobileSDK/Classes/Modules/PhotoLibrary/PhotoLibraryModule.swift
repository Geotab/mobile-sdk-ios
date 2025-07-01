import UIKit

class PhotoLibraryModule: Module {
    private static let moduleName = "photoLibrary"

    init(viewPresenter: any ViewPresenter) {
        super.init(name: PhotoLibraryModule.moduleName)
        functions.append(PickImageFunction(module: self,
                                           filesystem: FilesystemAccessHelper(),
                                           imageAccessor: ImageAccessHelper(viewPresenter: viewPresenter, sourceType: .photoLibrary)))
    }
}
