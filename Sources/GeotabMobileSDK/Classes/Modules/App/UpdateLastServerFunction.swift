import Foundation

class UpdateLastServerFunction: ModuleFunction {
    static let functionName: String = "updateLastServer"
    
    private weak var module: AppModule?
    init(module: AppModule) {
        self.module = module
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
            
        guard let module else {
            jsCallback(Result.failure(GeotabDriveErrors.InvalidObjectError))
            return
        }

        guard let server = argument as? String else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        guard isValidDomainName(server) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        module.lastServerAddressUpdated?(server)
        jsCallback(Result.success("undefined"))
    }
}
