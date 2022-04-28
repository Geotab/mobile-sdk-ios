import SafariServices

class BrowserModule: Module {

    let viewPresenter: ViewPresenter
    var inAppBrowserVC: SFSafariViewController?
    
    init(viewPresenter: ViewPresenter) {
        self.viewPresenter = viewPresenter
        super.init(name: "browser")
        functions.append(OpenBrowserWindowFunction(module: self))
        functions.append(CloseBrowserWindowFunction(module: self))
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        let extraTemplate = try! Module.templateRepo.template(named: "Module.Browser.Script")
        scripts += (try? extraTemplate.render()) ?? ""
    
        return scripts
    }
}
