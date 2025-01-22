import Foundation

enum SsoError: String {
    case sessionParseFailedError = "Failed parsing session."
    case sessionRetrieveFailedError = "Failed retrieving session."
}

class SsoModule: Module {
    private static let moduleName = "sso"
    
    init(viewPresenter: ViewPresenter) {
        super.init(name: SsoModule.moduleName)
        functions.append(SamlLoginFunction(module: self, viewPresenter: viewPresenter))
        functions.append(SamlLoginWithASFunction(module: self))
    }
}
