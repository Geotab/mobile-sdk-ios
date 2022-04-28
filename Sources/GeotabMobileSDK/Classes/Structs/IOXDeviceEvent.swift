//
//  File.swift
//  
//
//  Created by Anubhav Saini on 2022-03-18.
//

public enum EventType: Int, Codable {
    case ble
}

public struct IOXDeviceEvent: Codable {
    let type: EventType?
    let deviceEvent: DeviceEvent
    
    init(type: Int, deviceEvent: DeviceEvent) {
        self.type = EventType(rawValue: type)
        self.deviceEvent = deviceEvent
    }
}
