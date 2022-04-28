import Foundation

class DeviceEventTransformer {
    let jan1st2002Timestamp: UInt64 = 1009843200
    let milliseconds: UInt64 = 1_000
    let locationPrecision: Float = 10_000_000
    let rpmPrecision: Float = 4
    let odometerPrecision: Float = 10
    let engineHoursPrecision: Float = 10

    func transform(byteArray: Data) throws -> DeviceEvent {
        if byteArray.count < 40 {
            throw GeotabDriveErrors.IoxEventParsingError(error: "Error parsing DeviceEvent")
        }
        let timestamp = (byteArray[0...3].reversed().reduce(0) { $0 << 8 + UInt64($1) } + jan1st2002Timestamp) * milliseconds
        let dateTime = String(timestamp)
        
        let latitude = Float(byteArray[4...7].reversed().reduce(0) { $0 << 8 + Int32($1) }) / locationPrecision

        let longitude = Float(byteArray[8...11].reversed().reduce(0) { $0 << 8 + Int32($1) }) / locationPrecision

        let roadSpeed = Float(byteArray[12])

        let rpm = Float(byteArray[13...14].reversed().reduce(0) { $0 << 8 + Int32($1) }) / rpmPrecision

        let odometer = Float(byteArray[15...18].reversed().reduce(0) { $0 << 8 + Int32($1) }) / odometerPrecision

        let status = statusFlags(byteArray[19])

        let tripOdometer = Float(byteArray[20...23].reversed().reduce(0) { $0 << 8 + Int32($1) }) / odometerPrecision

        let engineHours = Float(byteArray[24...27].reversed().reduce(0) { $0 << 8 + Int32($1) }) / engineHoursPrecision

        let tripDuration = byteArray[28...31].reversed().reduce(0) { $0 << 8 + UInt64($1) } * milliseconds

        let vehicleIdInt = byteArray[32...35].reversed().reduce(0) { $0 << 8 + UInt64($1) }
        let vehicleId = String(vehicleIdInt)

        let driverIdInt = byteArray[36...39].reversed().reduce(0) { $0 << 8 + UInt64($1) }
        let driverId = String(driverIdInt)

        let rawData = byteArray

        return DeviceEvent(
            dateTime: dateTime,
            latitude: latitude,
            longitude: longitude,
            roadSpeed: roadSpeed,
            rpm: rpm,
            status: status,
            odometer: odometer,
            tripOdometer: tripOdometer,
            engineHours: engineHours,
            tripDuration: tripDuration,
            vehicleId: vehicleId,
            driverId: driverId,
            rawData: rawData
        )
    }

    private func statusFlags(_ byte: UInt8) -> String {
        var statusFlags = ""

        if byte & 0b00000001 != 0x00 {
            statusFlags += "GPS Latched"
        } else {
            statusFlags += "GPS Latched"
        }
        statusFlags += " | "
        
        if byte & 0b00000010 != 0x00 {
            statusFlags += "IGN on"
        } else {
            statusFlags += "IGN off"
        }
        statusFlags += " | "
        
        if byte & 0b00000100 != 0x00 {
            statusFlags += "Engine Data"
        } else {
            statusFlags += "No Engine Data"
        }
        statusFlags += " | "
        
        if byte & 0b00001000 != 0x00 {
            statusFlags += "Date/Time Valid"
        } else {
            statusFlags += "Date/Time Invalid"
        }
        statusFlags += " | "
        
        if byte & 0b00010000 != 0x00 {
            statusFlags += "Speed From Engine"
        } else {
            statusFlags += "Speed From GPS"
        }
        statusFlags += " | "
        
        if byte & 0b00100000 != 0x00 {
            statusFlags += "Distance From Engine"
        } else {
            statusFlags += "Distance From GPS"
        }
        return statusFlags
    }
}
