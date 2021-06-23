//
//  GoDevice.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-07.
//

public struct GoDevice: Codable {
    public let id: String
    public let name: String?
    public let activeFrom: String?
    public let activeTo: String?
    public let comment: String?
    public let deviceType: String?
    public let groups: [Group]?
    public let hardwareId: Int?
    public let productId: Int?
    public let serialNumber: String?
    public let timeZoneId: String?
    public let version: String?
    public let vehicleIdentificationNumber: String?
    public let engineVehicleIdentificationNumber: String?
    public let pinDevice: Bool?
    public let licensePlate: String?
    public let timeToDownload: String?
    public let enableMustReprogram: Bool?
    public let ignoreDownloadsUntil: String?
    public let minor: Int?
    public let major: Int?
    public let workTime: String?
    public let maxSecondsBetweenLogs: Float?
}


