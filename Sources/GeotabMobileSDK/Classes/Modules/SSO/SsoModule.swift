import Foundation

enum SsoError: String {
    case sessionParseFailedError = "Failed parsing session."
    case sessionRetrieveFailedError = "Failed retrieving session."
}

class SsoModule: Module {
    static let moduleName = "sso"

    let viewPresenter: ViewPresenter
    
    init(viewPresenter: ViewPresenter) {
        self.viewPresenter = viewPresenter
        super.init(name: SsoModule.moduleName)
        functions.append(SamlLoginFunction(module: self, name: "samlLogin"))
        functions.append(SamlLoginWithASFunction(module: self))
    }
}
