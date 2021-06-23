//
//  NativeActionEvent.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-22.
//

struct NativeActionEvent: Codable {
    let event: String
    let foreground: Bool
    let notification: Int
    let queued: Bool
}
