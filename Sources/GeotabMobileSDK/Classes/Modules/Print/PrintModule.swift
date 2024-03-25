import UIKit
import WebKit
import SafariServices

protocol PrintViewPresenter: ViewPresenter {
    func presentPrintController(completion: @escaping () -> Void)
}

class PrintModule: Module {
    static let moduleName = "print"

    let scriptGateway: ScriptGateway
    let viewPresenter: PrintViewPresenter

    init(scriptGateway: ScriptGateway, viewPresenter: PrintViewPresenter) {
        self.scriptGateway = scriptGateway
        self.viewPresenter = viewPresenter
        super.init(name: PrintModule.moduleName)
        functions.append(PrintFunction(module: self))
    }
}
