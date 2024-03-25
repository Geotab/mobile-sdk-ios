public typealias DriverActionNecessaryCallbackType = (_ isDriverActionNecessary: Bool, _ driverActionType: String) -> Void

public typealias PageNavigationCallbackType = (_ path: String) -> Void

public typealias LoginRequiredCallbackType = (_ status: String, _ errorMessage: String?) -> Void

public typealias LastServerAddressUpdatedCallbackType = (_ server: String) -> Void

/// :nodoc:
public typealias IOXDeviceEventCallbackType = (_ data: (Result<IOXDeviceEvent, Error>)) -> Void
