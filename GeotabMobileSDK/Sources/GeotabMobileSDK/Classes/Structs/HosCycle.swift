//
//  HosCycle.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-17.
//


public struct HosCycle: Codable {
    public let cycleDays: Int?
    public let cycleMaximum: Int?
    public let cycleRestartMinimum: Int?
    public let cycleRestMinimum: Int?
    public let cycleRestDays: Int?
    public let dutyMaximumSinceCycleRest: Int?
    public let maxPercentDriving: Float?
    public let cycleStatuses: [String?]?
}
