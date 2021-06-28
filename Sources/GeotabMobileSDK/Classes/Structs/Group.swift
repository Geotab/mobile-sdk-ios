//
//  GeotabGroup.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2019-12-03.
//

public struct Group: Codable {
    public let children: [Group]
    public let comments: String?
    public let id: String
    public let name: String?
    public let reference: String?
}
