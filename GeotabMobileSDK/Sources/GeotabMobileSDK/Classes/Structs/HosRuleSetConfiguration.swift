//
//  HosRuleSetConfiguration.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-17.
//

public struct HosRuleSetConfiguration: Codable {
    public let cycle: HosCycle?
    public let logRetentionDays: Int
    public let rest: HosRest?
    public let workday: HosWorkday?
    public let daily: HosDaily?
    public let bigDayBonus: Int?
    public let bigDayMaxPerCycle: Int?
    public let bigDayIgnoresCycleReset: Bool?
    public let oilwell: Bool?
    public let exempt: Bool?
    public let splitType: String?
    public let labsEnabled: Bool?
    public let customStartOfDay: Bool?
    public let resetPreviousCycle: Bool?
}
