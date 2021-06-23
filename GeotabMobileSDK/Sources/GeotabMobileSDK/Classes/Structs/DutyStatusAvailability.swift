//
//  DutyStatusAvailability.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-13.
//

public struct DutyStatusAvailability: Codable {
    public let cycle: String?
    public let cycleAvailabilities: [CycleAvailability]?
    public let cycleRest: String?
    public let driver: User?
    public let driving: String?
    public let duty: String?
    public let dutySinceCycleRest: String?
    public let is16HourExemptionAvailable: Bool?
    public let isAdverseDrivingExemptionAvailable: Bool?
    public let isOffDutyDeferralExemptionAvailable: Bool?
    public let recap: [OnDutyLog]
    public let rest: String?
    public let workday: String?
    
}
