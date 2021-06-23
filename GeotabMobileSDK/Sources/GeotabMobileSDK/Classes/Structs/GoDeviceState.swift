//
//  GoDeviceState.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-07.
//

/**
No document in MyGeotab API, some of the info may not be unavailable or correct due to lack of document
*/
struct GoDeviceState: Codable {
    let device: GoDevice
    let deviceCommunicating: Bool
    let driving: Bool?
    let diagnosticViewed: Bool
    let driverActionNecessary: Bool
    let eldDiagnostic: Bool
    let eldMalfunction: Bool
    let embed: Bool
    let gpsConnected: Bool
    let language: String
    let newMessage: Bool
    let newUpcomingViolation: Bool
    let noGeolocationSimulation: Bool
    let online: Bool
}
