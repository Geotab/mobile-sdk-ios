
import Foundation

class UpdateLastServerFunction: ModuleFunction {
    
    private let module: AppModule
    init(module: AppModule) {
        self.module = module
        super.init(module: module, name: "updateLastServer")
    }
    
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
            
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
