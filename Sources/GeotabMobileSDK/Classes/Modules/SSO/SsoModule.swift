import Foundation

class SsoModule: Module {
    static let moduleName = "sso"

    let viewPresenter: ViewPresenter
    
    init(viewPresenter: ViewPresenter) {
        self.viewPresenter = viewPresenter
        super.init(name: SsoModule.moduleName)
        functions.append(SamlLoginFunction(module: self, name: "samlLogin"))
        if #available(iOS 12.0, *) {
            functions.append(SamlLoginWithASFunction(module: self))
        }
    }
}
