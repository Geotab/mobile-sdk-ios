//
//  JsonUtil.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-24.
//
import Foundation

func toJson<T: Encodable>(_ val: T) -> String? {
    guard let data = try? JSONEncoder().encode(val) else {
        return nil
    }
    return String(data: data, encoding: .utf8)
}
