import UIKit
import WebKit
import SafariServices

class PrintModule: Module {
    let webDriveDelegate: WebDriveDelegate
    let viewPresenter: ViewPresenter

    init(webDriveDelegate: WebDriveDelegate, viewPresenter: ViewPresenter) {
        self.webDriveDelegate = webDriveDelegate
        self.viewPresenter = viewPresenter
        super.init(name: "print")
        functions.append(PrintFunction(module: self))
    }
    
}



