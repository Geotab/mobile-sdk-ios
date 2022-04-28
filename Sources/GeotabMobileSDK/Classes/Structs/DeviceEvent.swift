import Foundation

struct DeviceEvent: Codable {
    let dateTime: String
    let latitude: Float
    let longitude: Float
    let roadSpeed: Float
    let rpm: Float
    let status: String
    let odometer: Float
    let tripOdometer: Float
    let engineHours: Float
    let tripDuration: UInt64
    let vehicleId: String
    let driverId: String
    let rawData: Data
}
