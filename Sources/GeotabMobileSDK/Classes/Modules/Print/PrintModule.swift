import UIKit
import WebKit
import SafariServices

protocol PrintViewPresenter: ViewPresenter {
    func presentPrintController(completion: @escaping () -> Void)
}

class PrintModule: Module {
    static let moduleName = "print"

    weak var viewPresenter: PrintViewPresenter?

    init(viewPresenter: PrintViewPresenter) {
        self.viewPresenter = viewPresenter
        super.init(name: PrintModule.moduleName)
        functions.append(PrintFunction(module: self))
    }
}
