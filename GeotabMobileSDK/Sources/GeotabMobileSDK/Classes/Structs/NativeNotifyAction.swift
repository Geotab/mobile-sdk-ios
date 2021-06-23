//
//  NativeNotifyAction.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-22.
//

struct NativeNotifyAction: Codable {
    let id: String
    let title: String
    let type: String? // button or input
    let launch: Bool?
    let ui: String? // decline
}
