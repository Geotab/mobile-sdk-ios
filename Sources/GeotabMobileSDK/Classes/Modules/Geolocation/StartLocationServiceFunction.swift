import Foundation

struct StartLocationServiceArgument: Codable {
    let enableHighAccuracy: Bool?
}

class StartLocationServiceFunction: ModuleFunction {
    private let module: GeolocationModule
    init(module: GeolocationModule) {
        self.module = module
        super.init(module: module, name: "___startLocationService")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        var enableHA = false
        if argument != nil, JSONSerialization.isValidJSONObject(argument!), let argData = try? JSONSerialization.data(withJSONObject: argument!) {
            guard let argument = try? JSONDecoder().decode(StartLocationServiceArgument.self, from: argData) else {
                jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
                return
            }
            enableHA = argument.enableHighAccuracy ?? false
        }
        do {
            try module.startService(enableHighAccuracy: enableHA)
            jsCallback(Result.success("undefined"))
        } catch {
            jsCallback(Result.failure(error))
        }
    }
}
