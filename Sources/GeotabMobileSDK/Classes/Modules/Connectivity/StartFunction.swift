protocol ConnectivityStarting: Module {
    var started: Bool { get }
    func start() -> Bool
}

class StartFunction: ModuleFunction {
    private weak var starter: ConnectivityStarting?
    
    init(starter: ConnectivityStarting) {
        self.starter = starter
        super.init(module: starter, name: "start")
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        let result = start()
        jsCallback(Result.success("\(result)"))
    }
    
    func start() -> Bool {
        guard let starter = starter else {
            return false
        }
        
        guard !starter.started else {
            return true
        }

        return starter.start()
    }
}
