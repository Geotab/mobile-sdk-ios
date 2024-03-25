import UIKit

class PrintFunction: ModuleFunction {
    private let module: PrintModule
    init(module: PrintModule) {
        self.module = module
        super.init(module: module, name: "print")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        if let presentedViewController = module.viewPresenter.presentedViewController {
            guard presentedViewController.isBeingPresented == false
                    && presentedViewController.isBeingDismissed == false else {
                jsCallback(Result.success("undefined"))
                return
            }

          presentedViewController.dismiss(animated: true, completion: {
              self.module.viewPresenter.presentPrintController {
                  jsCallback(Result.success("undefined"))
              }
          })

        } else {
            self.module.viewPresenter.presentPrintController {
                jsCallback(Result.success("undefined"))
            }
        }
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        let extraTemplate = try! Module.templateRepo.template(named: "ModuleFunction.Print.Script")
        scripts += (try? extraTemplate.render()) ?? ""
        return scripts
    }
}
