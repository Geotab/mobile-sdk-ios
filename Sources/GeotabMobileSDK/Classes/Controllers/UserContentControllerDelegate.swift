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
    private var scriptInjectables: [String: any ScriptInjectable] = [:]
    private let modules: Set<Module>
    private weak var scriptGateway: (any ScriptGateway)?
    private var registeredHandlerNames: Set<String> = []
    public weak var didRecieveScriptDelegate: (any WVDidRecieveScriptDelegate)?
    
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
        
        didRecieveScriptDelegate?.didReceive(scriptMessage: message)
        
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
            if let jsonError = error as? (any JsonSerializableError),
               let json = jsonError.asJson {
                errorString = "(() => { const errObj = \(json); return Object.assign(new Error(errObj.message), errObj); })()"
            } else {
                errorString = "new Error(\"\(error.localizedDescription)\")"
            }
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

extension UserContentControllerDelegate {
    /**
     Registers a given ScriptInjectable object with the content controller, allowing it to be executed within the web view.
     
     The ScriptInjectable object encapsulates the source code, injection time, and message handler name for the custom script. By registering it, the custom script will be injected into the web view at the specified injection time and be able to communicate with native code using the provided message handler name.
     
     - Parameter scriptInjectable: The script injectable object containing the properties and logic needed to define and control the custom script.
     */
    func registerScriptInjectable(_ scriptInjectable: any ScriptInjectable) {
        let userScript = WKUserScript(source: scriptInjectable.source,
                                      injectionTime: scriptInjectable.injectionTime,
                                      forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        contentController.add(self, name: scriptInjectable.messageHandlerName)
        scriptInjectables[scriptInjectable.messageHandlerName] = scriptInjectable
    }
    /**
     Unregisters a given script injectable object from the content controller, removing it from execution within the web view.
     
     If the provided script injectable object is not found in the registered scripts, the method returns early without making any changes.
     
     - Parameter handlerName: The script injectable object's message handler name to be unregistered.
     */
    func unregisterScriptInjectable(_ handlerName: String) {
        guard let _ = scriptInjectables[handlerName] else { return }
        contentController.removeScriptMessageHandler(forName: handlerName)
        scriptInjectables.removeValue(forKey: handlerName)
    }
}
