
class StartFunction: ModuleFunction {
    private let module: ConnectivityModule
    
    init(module: ConnectivityModule) {
        self.module = module
        super.init(module: module, name: "start")
    }
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        let result = start()
        jsCallback(Result.success("\(result)"))
    }
    
    func start() -> Bool {
        if module.started {
            return module.started
        }

        do {
            try module.reachability?.startNotifier()
            module.started = true
            return true
        } catch {
            return false
        }
    }
}
