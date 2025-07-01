import UIKit

class CancelFunction: ModuleFunction {
    private static let cancelFunctionName: String = "cancel"
    private weak var module: LocalNotificationModule?
    
    init(module: LocalNotificationModule) {
        self.module = module
        super.init(module: module, name: Self.cancelFunctionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        guard let id = argument as? Int else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }

        cancel(id: id) { result in
            switch result {
            case .success(let notification): jsCallback(Result.success(toJson(notification)!))
            case .failure(let error): jsCallback(Result.failure(error))
            }
            
        }
        
    }
    
    public func cancel(id: Int, jsCallback: @escaping (Result<NativeNotify, any Error>) -> Void) {
        // find the nativeNotification
        guard let module,
              let getAllFunction = module.findFunction(name: "getAll") as? GetAllFunction else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionNotFoundError))
            return
        }
        getAllFunction.getAll { nts in
            
            guard let notification = nts.first(where: { $0.id == id }) else {
                jsCallback(Result.failure(GeotabDriveErrors.NotificationNotFound))
                return
            }
            
            let requestId = "\(id)"
            module.notificationAdapter?.removeDelivered(withIdentifiers: [requestId])
            module.notificationAdapter?.removePendingRequests(withIdentifiers: [requestId])
            
            jsCallback(Result.success(notification))
        }
    }
    
    override func scripts() -> String {
        guard let module else { return "" }

        var offName = "off"
        if let offFunction = module.findFunction(name: "off") as? OffFunction {
            offName = offFunction.name
        }

        let functionTemplate = try! Module.templateRepo.template(named: "ModuleFunction.LocalNotification.Cancel.Script")

        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": module.name, "geotabNativeCallbacks": Module.geotabNativeCallbacks, "callbackPrefix": Module.callbackPrefix, "off": offName, "functionName": name]

        guard let functionScript = try? functionTemplate.render(scriptData) else { return "" }

        return functionScript
    }
}
