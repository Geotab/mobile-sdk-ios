//
//  HosRest.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-17.
//

public struct HosRest: Codable {
    public let betweenRestLimit: Int?
    public let restBreakMinimum: Int
    public let dailyRestMinimum: Int?
}
