import UIKit

class PrintFunction: ModuleFunction {
    private static let functionName: String = "print"
    private weak var module: PrintModule?
    init(module: PrintModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        if let presentedViewController = module?.viewPresenter?.presentedViewController {
            guard presentedViewController.isBeingPresented == false
                    && presentedViewController.isBeingDismissed == false else {
                jsCallback(Result.success("undefined"))
                return
            }

          presentedViewController.dismiss(animated: true, completion: { [weak self] in
              self?.module?.viewPresenter?.presentPrintController {
                  jsCallback(Result.success("undefined"))
              }
          })

        } else {
            module?.viewPresenter?.presentPrintController {
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
