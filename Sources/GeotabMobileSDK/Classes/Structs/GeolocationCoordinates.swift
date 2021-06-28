//
//  GeolocationCoordinates.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-08-24.
//

struct GeolocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let accuracy: Double // horizontalAccuracy
    let altitudeAccuracy: Double? // verticalAccuracy
    let heading: Double? // course
    let speed: Double?
}
