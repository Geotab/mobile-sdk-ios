// Copyright © 2021 Geotab Inc. All rights reserved.

struct GeolocationPosition: Codable {
    let coords: GeolocationCoordinates
    let timestamp: UInt64
}
