//
//  IoxBleModule.swift
//  GeotabMobileSDK
//
//  Created by Yunfeng Liu on 2021-02-10.
//

import Foundation
import CoreBluetooth

class IoxBleModule: Module {
    
    private let webDriveDelegate: WebDriveDelegate
    private var started = false
    private var startListener: ((Result<String, Error>) -> Void)?
    
    lazy var peripheralManager: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    
    var service: CBMutableService?
    
    let charId = CBUUID(nsuuid: UUID(uuidString: "0660B6DE-295B-4200-A016-7824C6F9618C")!)
    lazy var char = CBMutableCharacteristic(type: charId, properties: [.write], value: nil, permissions: [.writeable])
    
    lazy var chars: [CBMutableCharacteristic] = [
        char
    ]
    
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        super.init(name: "ioxble")
        functions.append(StartIoxBleFunction(module: self))
        functions.append(StopIoxBleFunction(module: self))
    }
    
    func callStartListener(result: Result<String, Error>) {
        guard startListener != nil else {
            return
        }
        startListener!(result)
        startListener = nil
        service = nil // done handling service
    }
    
    func authStateDeniedOrRestricted() -> Bool {
        var denRes = false
        if #available(iOS 13, *) {
            let authStatus = peripheralManager.authorization
            denRes = authStatus == .restricted || authStatus == .denied
        } else {
            let authStatus = CBPeripheralManager.authorizationStatus()
            denRes = authStatus == .restricted || authStatus == .denied
        }
        return denRes
    }
    
    func authStateNotDetermined() -> Bool {
        var notDet = false
        if #available(iOS 13, *) {
            notDet = peripheralManager.authorization == .notDetermined
        } else {
            notDet = CBPeripheralManager.authorizationStatus() == .notDetermined
        }
        return notDet
    }
    
    // main thread
    func start(serviceId: String, _ jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        guard startListener == nil else {
            jsCallback(Result.failure(GeotabDriveErrors.IoxBleError(error: "One call at a time only")))
            return
        }
        
        startListener = jsCallback
        
        guard !started else {
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "Service is already started")))
            return
        }
        
        guard service == nil else {
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "Another service is in starting progress")))
            return
        }
        
        guard let uuid = UUID(uuidString: serviceId) else {
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "\(serviceId) is not an UUID")))
            return
        }
        
        // remember service that needs to be started
        let serviceId = CBUUID(nsuuid: uuid)
        service = CBMutableService(type: serviceId, primary: true)
        service!.characteristics = chars
        
        let state = peripheralManager.state
        
        switch state {
        case .poweredOff:
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE is power off state")))
            stop()
        case .unauthorized:
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE is unauthorized")))
            stop()
        case .unsupported:
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE is unsupported")))
            stop()
        case .poweredOn:
            startServiceIfNotYet()
        default:
            if authStateDeniedOrRestricted() {
                callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE usage is unauthorized")))
                stop()
            } else if authStateNotDetermined() {
                print("Not Determined")
            }
        }
    }
    
    func stop() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        started = false
        service = nil
        
    }
    
    private func startServiceIfNotYet() {
        guard !started else {
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "Another service is already started")))
            return
        }
        guard let serv = service else {
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "No service to be started")))
            stop()
            return
        }
        // here we are assuming only one service is going to be used
        peripheralManager.removeAllServices()
        peripheralManager.add(serv)
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "ioxble",
            CBAdvertisementDataServiceUUIDsKey: [serv.uuid]
        ])
        
    }
    
}

extension IoxBleModule: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .unknown:
            break
        case .unsupported:
            if started && startListener == nil {
                webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: new Error('BLE is unsupported') }"))
            }
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE is unsupported")))
            stop()
        case .unauthorized:
            if started && startListener == nil {
                webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: new Error('BLE is unauthorized') }"))
            }
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE usage is unauthorized")))
            stop()
        case .resetting:
            break
        case .poweredOn:
            startServiceIfNotYet()
        case .poweredOff:
            if started && startListener == nil {
                webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: new Error('BLE is power off state') }"))
            }
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE is in Power off state")))
            stop()
        @unknown default:
            if started && startListener == nil {
                webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: new Error('Unknown error') }"))
            }
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "Unknown error")))
            stop()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error != nil {
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE failed adding the service")))
            stop()
            return
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE failed advertising the service")))
            stop()
            return
        }
        callStartListener(result: Result.success("undefined"))
        started = true
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        for req in requests {
            guard let data = req.value else {
                continue
            }
            
            do {
                let ioxData = try GoDeviceData(serializedData: data)
                let json = try ioxData.jsonString()
                // send json to web drive
                if started {
                    webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.godevicedata", params: "{ detail: \(json) }"))
                }
                print("JSON: \(json)")
            } catch {
                print("Transforming GoDeviceData failed \(error)")
            }
        }
        
    }
}
