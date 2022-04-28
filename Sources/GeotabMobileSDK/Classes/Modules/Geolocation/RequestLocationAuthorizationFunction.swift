import Foundation

class RequestLocationAuthorizationFunction: ModuleFunction {
    private let module: GeolocationModule
    init(module: GeolocationModule) {
        self.module = module
        super.init(module: module, name: "___requestLocationAuthorization")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        if module.isNotDetermined() {
            module.requestAuthorizationWhenInUse()
        } else if module.isAuthorizedWhenInUse() {
            module.requestAuthorizationAlways()
        }
        jsCallback(Result.success("undefined"))
    }
}
