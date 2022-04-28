import Foundation

private protocol Message {
    var data: Data { get }
}

internal enum Messages {
    static let handshake: [UInt8] = [0x02, 0x01, 0x00, 0x03, 0x08, 0x03]
    static let ack: [UInt8] = [0x02, 0x02, 0x00, 0x04, 0x0A, 0x03]
    static let stx: UInt8 = 0x02
    static let etx: UInt8 = 0x03
    static let goDeviceMessageType: UInt8 = 0x21
}

internal func checksum(for bytes: [UInt8]) -> [UInt8] {
    var check1: UInt8 = 0
    var check2: UInt8 = 0
    for byte in bytes {
        check1 = check1.addingReportingOverflow(byte).partialValue
        check2 = check2.addingReportingOverflow(check1).partialValue
    }
    return [check1, check2]
}

internal class SyncMessage: Message {
    var data: Data {
        let sync: [UInt8] = [0x55]
        return Data(bytes: sync, count: 1)
    }
}

internal class ChecksumMessage: Message {
    let messageType: UInt8
    let payload: [UInt8]
    init(messageType: UInt8, payload: [UInt8]) {
        self.messageType = messageType
        self.payload = payload
    }
    
    var data: Data {
        var bytes = [Messages.stx, messageType]
        bytes.append(contentsOf: [UInt8(payload.count & 0xFF)])
        bytes.append(contentsOf: payload)
        bytes.append(contentsOf: checksum(for: bytes))
        bytes.append(Messages.etx)
        return Data(bytes: bytes, count: bytes.count)
    }
}

internal class HandshakeConfirmationMessage: ChecksumMessage {
    private let deviceID: [UInt8] = [0x2D, 0x10]
    private let flags: [UInt8] = [0x01, 0x00]

    required init() {
        var payload = deviceID
        payload.append(contentsOf: flags)
        super.init(messageType: 0x81, payload: payload)
    }
}

internal class GoDeviceDataMessage: ChecksumMessage {
    required init(bytes: [UInt8]) throws {
        let length = Int(bytes[2])
        let calculatedChecksum = checksum(for: Array(bytes[0..<bytes.count - 3]))
        guard
            bytes.count >= 6,
            bytes[0] == Messages.stx,
            bytes[1] == Messages.goDeviceMessageType,
            bytes.last == Messages.etx,
            bytes.count == length + 6,
            calculatedChecksum == Array(bytes[bytes.count - 3..<bytes.count - 1])
        else {
            throw GeotabDriveErrors.IoxBleError(error: "Invalid data payload")
        }
        
        let payload = Array(bytes[3..<bytes.count - 3])
        super.init(messageType: Messages.goDeviceMessageType, payload: payload)
    }
}

internal func isGoDeviceData(_ data: [UInt8]) -> Bool {
    return data.count >= 6 && data[1] == Messages.goDeviceMessageType
}
