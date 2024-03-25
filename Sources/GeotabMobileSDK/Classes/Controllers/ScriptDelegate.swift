import WebKit

protocol ScriptEvaluating: NSObject {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
}

class ScriptDelegate: NSObject, ScriptGateway {
 
    enum PushErrors: Error {
        case InvalidJSON
        case InvalidModuleEvent
    }

    @TaggedLogger("ScriptDelegate")
    private var logger

    private weak var scriptEvaluator: ScriptEvaluating?
    
    init(scriptEvaluator: ScriptEvaluating) {
        self.scriptEvaluator = scriptEvaluator
    }

    func push(moduleEvent: ModuleEvent, completed: @escaping (Result<Any?, Error>) -> Void) {
        guard let scriptEvaluator = self.scriptEvaluator else {
            $logger.debug("No script evaluator")
            return
        }
        
        if moduleEvent.event.contains("\"") ||  moduleEvent.event.contains("\'") {
            $logger.debug("Pushed invalid event")
            completed(Result.failure(PushErrors.InvalidModuleEvent))
            return
        }
        
        let jsonString = moduleEvent.params
        let jsonData = jsonString.data(using: String.Encoding.utf8)!
        
        do {
            _ =  try JSONSerialization.jsonObject(with: jsonData)
        } catch {
            $logger.debug("Pushed event with non JSON parameters")
            completed(Result.failure(PushErrors.InvalidJSON))
            return
        }
        
        let script = """
            window.dispatchEvent(new CustomEvent("\(moduleEvent.event)", \(moduleEvent.params)));
        """
        
        scriptEvaluator.evaluateJavaScript(script) { result, error in
            if let error {
                completed(Result.failure(error))
            } else {
                completed(Result.success(result))
            }
        }
    }
    
    func evaluate(script: String, completed: @escaping (Result<Any?, Error>) -> Void) {
        guard let scriptEvaluator = self.scriptEvaluator else {
            $logger.debug("No script evaluator")
            return
        }

        scriptEvaluator.evaluateJavaScript(script) { result, error in
            if let error {
                completed(Result.failure(error))
            } else {
                completed(Result.success(result))
            }
        }
    }

}
