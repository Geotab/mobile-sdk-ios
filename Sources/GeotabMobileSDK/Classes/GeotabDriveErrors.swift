import Foundation

/**
 Geotab SDK Error Types
 */
public enum GeotabDriveErrors: Error {
    /**
     Indicates there's a duplicate Module Function existed.
     */
    case DuplicateModuleFunctionError
    /**
     Indicates failure registering module function
     */
    case ModuleFunctionRegistrationError
    /**
     Indicate there's an error pushing Module Event to Drive.
     */
    case ModuleEventPushError
    /**
     Indicates the argument passed to Module function is not right.
     */
    case ModuleFunctionArgumentError
    /**
     Indicates there's something wrong of the API call to Drive. Usually because of the environment in Drive has changed and the previous call request became orphan.
     */
    case InvalidCallError
    /**
     Indicuates that an API call to Drive has timed out. Such error happens when Drive could not deliver the API call result back in time.
     */
    case ApiCallTimeoutError
    /**
     Indicates that an API call to the Drive failed from Javascript. For example when js failed providing result, it provides error.
     */
    case JsIssuedError(error: String)
    /**
     Module function not found.
     */
    case ModuleFunctionNotFoundError
    /**
     Local Notification module failed scheduling a notification.
     */
    case ScheduleNotificationError
    /**
     The notification in context is not found.
     */
    case NotificationNotFound
    /**
     The underlying device/resource for Image Picker is not available.
     */
    case NoImageFileAvailableError
    /**
     Something wrong with the capture image request.
     */
    case CaptureImageError(error: String)
    /**
     File exception related to a file operation.
     */
    case FileException(error: String)
    /**
     Geolocation error.
     */
    case GeolocationError(error: String)
    /**
     Error related to App Module
     */
    case AppModuleError(error: String)
    /**
     Error related to Browser Module.
     */
    case BrowserModuleError(error: String)
    /**
     Error related to Motion activity module
     */
    case MotionActivityError(error: String)
    /**
     Error related to IOX BLE module.
     */
    case IoxBleError(error: String)
    
    case AddAppDeviceError(error: String)
    
    case SamlLoginError(error: String)
    
    case SamlLoginCancelled
    /**
     Error related to IOX Data Parsing.
     */
    case IoxEventParsingError(error: String)
    
    case OperationCallFailed(error: String)
}

extension GeotabDriveErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .DuplicateModuleFunctionError:
            return "GeotabDriveErrors[DuplicateModuleFunctionError]"
        case .ModuleFunctionRegistrationError:
            return "GeotabDriveErrors[ModuleFunctionRegistrationError]"
        case .ModuleEventPushError:
            return "GeotabDriveErrors[ModuleEventPushError]"
        case .ModuleFunctionArgumentError:
            return "GeotabDriveErrors[ModuleFunctionArgumentError]"
        case .InvalidCallError:
            return "GeotabDriveErrors[InvalidCallError]"
        case .ApiCallTimeoutError:
            return "GeotabDriveErrors[ApiCallTimeoutError]"
        case .JsIssuedError(let errMsg):
            return "GeotabDriveErrors[JsIssuedError]: \(errMsg)"
        case .ModuleFunctionNotFoundError:
            return "GeotabDriveErrors[ModuleFunctionNotFoundError]"
        case .ScheduleNotificationError:
            return "GeotabDriveErrors[ScheduleNotificationError]"
        case .NotificationNotFound:
            return "GeotabDriveErrors[NotificationNotFound]"
        case .NoImageFileAvailableError:
            return "GeotabDriveErrors[NoImageFileAvailableError]"
        case .CaptureImageError(let errMsg):
            return "GeotabDriveErrors[CaptureImageError]: \(errMsg)"
        case .FileException(let errMsg):
            return "GeotabDriveErrors[FileException]: \(errMsg)"
        case .GeolocationError(let errMsg):
            return "GeotabDriveErrors[GeolocationError]: \(errMsg)"
        case .AppModuleError(let errMsg):
            return "GeotabDriveErrors[AppModuleError]: \(errMsg)"
        case .BrowserModuleError(let errMsg):
            return "GeotabDriveErrors[BrowserModuleError]: \(errMsg)"
        case .MotionActivityError(let errMsg):
            return "GeotabDriveErrors[MotionActivityError]: \(errMsg)"
        case .IoxBleError(let errMsg):
            return "GeotabDriveErrors[IoxBleError]: \(errMsg)"
        case .AddAppDeviceError(let errMsg):
            return "GeotabDriveErrors[AddAppDeviceError]: \(errMsg)"
        case .SamlLoginError(let errMsg):
            return "GeotabDriveErrors[SamlLoginError]: \(errMsg)"
        case .SamlLoginCancelled:
            return "GeotabDriveErrors[SamlLoginCancelled]"
        case .IoxEventParsingError(let errMsg):
            return "GeotabDriveErrors[IoxEventParsingError]: \(errMsg)"
        case .OperationCallFailed(let errMsg):
            return "GeotabDriveErrors[OperationCallFailed]: \(errMsg)"
        }
    }
}
