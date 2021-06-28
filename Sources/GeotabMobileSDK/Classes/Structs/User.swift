//
//  GeotabUser.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-03.
//

public struct User: Codable {
    public let acceptedEULA: Int
    public let activeDashboardReports: [String] // Wrong on document, this should be an array type, not string
    public let activeFrom: String // "1986-01-01T00:00:00.000Z"
    public let activeTo: String
    public let authorityAddress: String
    public let authorityName: String
    public let availableDashboardReports: [String] // Wrong on document, this should be an array type, not string
    public let cannedResponseOptions: [String] // Wrong on document, this should be an array type, not string
    public let changePassword: Bool
    public let comment: String
    public let companyGroups: [Group]
    public let dateFormat: String
    public let defaultGoogleMapStyle: String
    public let defaultHereMapStyle: String
    public let defaultMapEngine: String
    public let defaultOpenStreetMapStyle: String
    public let defaultPage: String
    public let designation: String
    public let driveGuideVersion: Int
    public let electricEnergyEconomyUnit: String
    public let employeeNo: String
    public let firstDayOfWeek: String
    public let firstName: String
    public let fuelEconomyUnit: String
    public let hosRuleSet: String
    public let id: String
    public let isDriver: Bool?
    public let isEULAAccepted: Bool
    public let isEmailReportEnabled: Bool
    public let isLabsEnabled: Bool
    public let isMetric: Bool
    public let isNewsEnabled: Bool
    public let isPersonalConveyanceEnabled: Bool
    public let isYardMoveEnabled: Bool
    public let language: String
    public let lastName: String
//    public let mapViews: String // definition is unclear in doc. ignoring for now
    public let name: String
    public let password: String?
    public let privateUserGroups: [Group]
    public let reportGroups: [Group]
    public let securityGroups: [Group]
    public let showClickOnceWarning: Bool
    public let timeZoneId: String
    public let zoneDisplayMode: String
    public let version: String?
}
