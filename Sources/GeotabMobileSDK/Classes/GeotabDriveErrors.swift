public import Foundation

// swift-format-ignore: AlwaysUseLowerCamelCase

/**
 Geotab SDK Error Types
 */
public enum GeotabDriveErrors: Error {
    /**
     A duplicate ModuleFunction has been defined.
     */
    case DuplicateModuleFunctionError
    /**
     A failure registering a module function.
     */
    case ModuleFunctionRegistrationError
    /**
     An error pushing Module Event to Drive.
     */
    case ModuleEventPushError
    /**
     The argument passed to a Module Function is incorrect.
     */
    case ModuleFunctionArgumentError
    /**
     There's an issue with the API call. A common issue is that Drive has changed and the previous call request became orphaned.
     */
    case InvalidCallError
    /**
     An API call to Drive has timed out.
     */
    case ApiCallTimeoutError
    /**
     An API call to the Drive failed at the Javascript layer.
     */
    case JsIssuedError(error: String)
    /**
     A Module Function was not found.
     */
    case ModuleFunctionNotFoundError
    /**
     Local Notification module failed scheduling a notification.
     */
    case ScheduleNotificationError
    /**
     The notification is not found in the current context.
     */
    case NotificationNotFound
    /**
     The underlying device/resource for Image Picker is not available.
     */
    case NoImageFileAvailableError
    /**
     Something went wrong with the capture image request.
     */
    case CaptureImageError(error: String)
    /**
     An exception has occured related to a file operation.
     */
    case FileException(error: String)
    /**
     Geolocation error.
     */
    case GeolocationError(error: String)
    /**
     Error related to the App Module
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
    /**
     Error related to Local Storage Module
     */
    case StorageModuleError(error: String)
    /**
    Indicates a required object is invalid or has been released from memory
    */
    case InvalidObjectError
    
    case PushNotificationModuleError(error: String)
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
        case .StorageModuleError(let errMsg):
            return "GeotabDriveErrors[StorageModuleError]: \(errMsg)"
        case .InvalidObjectError:
            return "GeotabDriveErrors[InvalidObjectError]"
        case .PushNotificationModuleError(let errMsg):
            return "GeotabDriveErrors[PushNotificationModuleError]: \(errMsg)"
        }
    }
}
