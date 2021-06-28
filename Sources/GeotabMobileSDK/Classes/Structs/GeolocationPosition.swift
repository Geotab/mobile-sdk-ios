//
//  GeolocationPosition.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-08-24.
//

struct GeolocationPosition: Codable {
    let coords: GeolocationCoordinates
    let timestamp: UInt64
}
