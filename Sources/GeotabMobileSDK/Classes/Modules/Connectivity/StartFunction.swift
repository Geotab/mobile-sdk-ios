protocol ConnectivityStarting: Module {
    var started: Bool { get }
    func start() -> Bool
}

class StartFunction: ModuleFunction {
    private static let functionName: String = "start"
    private weak var starter: (any ConnectivityStarting)?
    
    init(starter: any ConnectivityStarting) {
        self.starter = starter
        super.init(module: starter, name: Self.functionName)
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
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
