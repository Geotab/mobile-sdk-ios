//
//  Bundle-Extension.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-10-15.
//
import Foundation

extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
    
    var version: String? {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
