//
//  StateModule.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-07.
//

class StateModule: Module {
    let webDriveDelegate: WebDriveDelegate
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        super.init(name: "state")
        functions.append(DeviceFunction(module: self))
        functions.append(DeviceCommunicatingFunction(module: self))
        functions.append(DrivingFunction(module: self))
        functions.append(GpsConnectedFunction(module: self))
    }
}
