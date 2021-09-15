

import UIKit

class PhotoLibraryModule: Module {
    let webDriveDelegate: WebDriveDelegate
    let viewPresenter: ViewPresenter
    let imagePicker = UIImagePickerController()
    init(webDriveDelegate: WebDriveDelegate, viewPresenter: ViewPresenter, moduleContainer: ModuleContainerDelegate) {
        self.webDriveDelegate = webDriveDelegate
        self.viewPresenter = viewPresenter
        super.init(name: "photoLibrary")
        functions.append(PickImageFunction(module: self, moduleContainer: moduleContainer))
    }
}
