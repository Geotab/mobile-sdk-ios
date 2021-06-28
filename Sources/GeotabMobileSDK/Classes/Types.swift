//
//  Types.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-03.
//

public typealias CallbackWithType<T> = (_ result: Result<T, Error>) -> Void

public typealias DriverActionNecessaryCallbackType = (_ isDriverActionNecessary: Bool, _ driverActionType: String) -> Void

public typealias PageNavigationCallbackType = (_ path: String) -> Void

public typealias LoginRequiredCallbackType = (_ status: String, _ errorMessage: String?) -> Void

public typealias LastServerAddressUpdatedCallbackType = (_ server: String) -> Void

