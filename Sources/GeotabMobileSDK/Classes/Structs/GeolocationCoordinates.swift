

struct GeolocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let accuracy: Double // horizontalAccuracy
    let altitudeAccuracy: Double? // verticalAccuracy
    let heading: Double? // course
    let speed: Double?
}
