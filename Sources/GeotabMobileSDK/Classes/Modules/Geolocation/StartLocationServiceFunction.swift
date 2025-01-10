import Foundation

struct StartLocationServiceArgument: Codable {
    let enableHighAccuracy: Bool?
}

protocol LocationServiceStarting: Module {
    func startService(enableHighAccuracy: Bool) throws
}

class StartLocationServiceFunction: ModuleFunction {
    static let functionName: String = "___startLocationService"
    private weak var starter: LocationServiceStarting?
    init(starter: LocationServiceStarting) {
        self.starter = starter
        super.init(module: starter, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        var enableHighAccuracy = false
        
        if let argument = argument {
            guard JSONSerialization.isValidJSONObject(argument),
                  let argData = try? JSONSerialization.data(withJSONObject: argument),
                  let decodedArgument = try? JSONDecoder().decode(StartLocationServiceArgument.self, from: argData) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            enableHighAccuracy = decodedArgument.enableHighAccuracy ?? false
        }
        
        do {
            try starter?.startService(enableHighAccuracy: enableHighAccuracy)
            jsCallback(Result.success("undefined"))
        } catch {
            jsCallback(Result.failure(error))
        }
    }
}
