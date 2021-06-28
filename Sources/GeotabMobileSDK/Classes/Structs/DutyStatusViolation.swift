//
//  DutyStatusViolation.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-19.
//

public struct DutyStatusViolation: Codable {
    public let driver: User?
    public let drivingDuration: String
    public let fromDate: String
    public let toDate: String?
    public let reason: String
    public let type: String
    public let id: String?
}
