import WebKit

protocol ScriptEvaluating: NSObject {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, (any Error)?) -> Void)?)
}

class ScriptDelegate: NSObject, ScriptGateway {
 
    enum PushErrors: Error {
        case invalidJSON
        case invalidModuleEvent
    }

    @TaggedLogger("ScriptDelegate")
    private var logger

    private weak var scriptEvaluator: (any ScriptEvaluating)?
    
    init(scriptEvaluator: any ScriptEvaluating) {
        self.scriptEvaluator = scriptEvaluator
    }

    func push(moduleEvent: ModuleEvent, completed: @escaping (Result<Any?, any Error>) -> Void) {
        guard let scriptEvaluator = self.scriptEvaluator else {
            $logger.debug("No script evaluator")
            return
        }
        
        if moduleEvent.event.contains("\"") ||  moduleEvent.event.contains("\'") {
            $logger.debug("Pushed invalid event")
            completed(Result.failure(PushErrors.invalidModuleEvent))
            return
        }
        
        let jsonString = moduleEvent.params
        let jsonData = jsonString.data(using: String.Encoding.utf8)!
        
        do {
            _ =  try JSONSerialization.jsonObject(with: jsonData)
        } catch {
            $logger.debug("Pushed event with non JSON parameters")
            completed(Result.failure(PushErrors.invalidJSON))
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
    
    func evaluate(script: String, completed: @escaping (Result<Any?, any Error>) -> Void) {
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
