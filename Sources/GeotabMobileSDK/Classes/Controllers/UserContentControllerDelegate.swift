import WebKit
import SafariServices
import Mustache

/// The wrapper holds only a **weak reference** to the actual handler (UserContentControllerDelegate),
/// allowing it to be deallocated when no other strong references exist. When the handler is deallocated,
/// messages are safely ignored via the optional chaining (`handler?.userContentController(...)`).
private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var handler: (any WKScriptMessageHandler)?

    init(handler: any WKScriptMessageHandler) {
        self.handler = handler
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handler?.userContentController(userContentController, didReceive: message)
    }
}

class UserContentControllerDelegate: NSObject, WKScriptMessageHandler {

    @TaggedLogger("UserContentControllerDelegate")
    private var logger

    let contentController = WKUserContentController()
    
    private let modules: Set<Module>
    private weak var scriptGateway: (any ScriptGateway)?
    private var registeredHandlerNames: Set<String> = []
    
    init(modules: Set<Module>,
         scriptGateway: any ScriptGateway) {
        self.modules = modules
        self.scriptGateway = scriptGateway
        super.init()
        setup()
    }

    private func setup() {
        // Use weak wrapper to prevent retain cycle
        let handler = WeakScriptMessageHandler(handler: self)
        modules.forEach { module in
            contentController.add(handler, name: module.name)
            registeredHandlerNames.insert(module.name)
        }
        let injectedScript = WKUserScript(source: injectedScriptSource(),
                                          injectionTime: .atDocumentEnd,
                                          forMainFrameOnly: true)
        contentController.addUserScript(injectedScript)
    }

    deinit {
        // Clean up message handlers to prevent memory leaks
        registeredHandlerNames.forEach { name in
            contentController.removeScriptMessageHandler(forName: name)
        }
        $logger.debug("UserContentControllerDelegate deinitialized")
    }
    
    private func injectedScriptSource() -> String {
        let namespaceDefinitions = """
        window.\(Module.geotabModules) = {};
        window.\(Module.geotabNativeCallbacks) = {};
        """
        
        var scripts = self.modules.reduce(namespaceDefinitions, { $0 + $1.scripts() })
        
        if let deviceReadyTemplate = try? Module.templateRepo.template(named: "Module.DeviceReady.Script"),
           let deviceReadyScript = try? deviceReadyTemplate.render() {
            scripts += deviceReadyScript
        } else {
            $logger.debug("Could not load device ready script")
        }
        
        // Following line is important, without it, WKwebview will report error
        // Without it, following line will error out with:
        // Optional(Error Domain=WKErrorDomain Code=5 "JavaScript execution returned a result of an unsupported type" UserInfo={NSLocalizedDescription=JavaScript execution returned a result of an unsupported type})
        scripts += "\"success\";"
        
        return scripts
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let msg = message.body as? String else {
            $logger.debug("Received message with empty body")
            return
        }
        
        let module = message.name
        let data = Data(msg.utf8)
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                $logger.debug("Could not parse message as JSON")
                return
            }
            guard let function = json["function"] as? String else {
                $logger.debug("Function name not found in message")
                return
            }
            guard let callback = json["callback"] as? String else {
                $logger.debug("Callback name not found in message")
                return
            }
            let params = json["params"]
            guard let moduleFunction = modules.findFunction(in: module, function: function) else {
                $logger.debug("function not found")
                return
            }
            callModuleFunction(moduleFunction: moduleFunction, callback: callback, params: params)
        } catch {
            $logger.debug("Error parsing message")
        }
    }
    
    private func scriptFor(_ callback: String, result: String?, error: (any Error)?) -> String {
        var errorString = "null"
        if let error {
            errorString = "new Error(\"\(error.localizedDescription)\")"
        }
        
        let resultString = result ?? "null"

        return """
            try {
                var t = \(callback)(\(errorString), \(resultString));
                if (t instanceof Promise) {
                    t.catch(err => { console.log(">>>>> Unexpected exception: ", err); });
                }
            } catch(err) {
                console.log(">>>>> Unexpected exception: ", err);
            }
        """
    }
    
    private func callModuleFunction(moduleFunction: ModuleFunction, callback: String, params: Any?) {
        moduleFunction.handleJavascriptCall(argument: params) { [weak self] result in
            guard let self,
                  let scriptGateway = self.scriptGateway else {
                return
            }
            
            var script: String?
            
            switch result {
            case .success(let result):
                script = self.scriptFor(callback, result: result, error: nil)
            case .failure(let error):
                script = self.scriptFor(callback, result: nil, error: error)
            }
            
            if let script {
                scriptGateway.evaluate(script: script, completed: {_ in })
            } else {
                self.$logger.debug("Could not create script to evaluate for callback")
            }
        }
    }
}
