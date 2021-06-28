//
//  HosWorkday.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-17.
//

public struct HosWorkday: Codable {
    public let driveMaximum: Int?
    public let offDutyMinimum: Int
    public let workdayMaximum: Int?
    public let dutyMaximum: Int?
}
