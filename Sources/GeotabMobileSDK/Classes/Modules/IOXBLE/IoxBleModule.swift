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
    private let executer: AsyncMainExecuterAdapter
    private let queue: OperationQueue
    private let transformer: DeviceEventTransformer = DeviceEventTransformer()
    
    private var isStarted = false
    private var isConnected = false
    private var startListener: ((Result<String, Error>) -> Void)?
    private var partialGoData: PartialGoData = PartialGoData()
    
    private lazy var peripheralManager: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    private var central: CBCentral?
    private var service: CBMutableService?
    
    private let notifyCharId = CBUUID(nsuuid: UUID(uuidString: "430F2EA3-C765-4051-9134-A341254CFD00")!)
    private let writeCharId = CBUUID(nsuuid: UUID(uuidString: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")!)
    private lazy var notifyChar = CBMutableCharacteristic(type: notifyCharId, properties: [.notify, .read], value: nil, permissions: [.readable, .writeable])
    private lazy var writeChar = CBMutableCharacteristic(type: writeCharId, properties: [.writeWithoutResponse], value: nil, permissions: [.writeable])
    private lazy var descriptor = CBMutableDescriptor(type: CBUUID(string: "2902"), value: nil)
    
    
    convenience init(webDriveDelegate: WebDriveDelegate) {
        self.init(webDriveDelegate: webDriveDelegate, executer: MainExecuter(), queue: OperationQueue())
    }
    
    // init for testing
    init(webDriveDelegate: WebDriveDelegate, executer: AsyncMainExecuterAdapter, queue: OperationQueue) {
        self.webDriveDelegate = webDriveDelegate
        self.executer = executer
        self.queue = queue
        super.init(name: "ioxble")
        functions.append(StartIoxBleFunction(module: self))
        functions.append(StopIoxBleFunction(module: self))
    
        self.queue.qualityOfService = .userInitiated
        self.queue.maxConcurrentOperationCount = 1
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
    
    func start(serviceId: String, _ jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        guard startListener == nil else {
            jsCallback(Result.failure(GeotabDriveErrors.IoxBleError(error: "One call at a time only")))
            return
        }
        
        startListener = jsCallback
        
        guard !isStarted else {
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
        notifyChar.descriptors?.append(descriptor)
        service!.characteristics = [notifyChar, writeChar]
        
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
        queue.cancelAllOperations()
        queue.isSuspended = true
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        isConnected = false
        isStarted = false
        service = nil
    }
    
    private func startServiceIfNotYet() {
        guard !isStarted else {
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
    
    private func sendSyncMessage() {
        guard !isConnected else {
            return
        }
        if let central = central {
            peripheralManager.updateValue(SyncMessage().data, for: notifyChar, onSubscribedCentrals: [central])
        }
        executer.after(1) {
            self.sendSyncMessage()
        }
    }
    
    private func sendHandshakeConfirmationMessage() {
        if let central = central {
            peripheralManager.updateValue(HandshakeConfirmationMessage().data, for: notifyChar, onSubscribedCentrals: [central])
        }
    }
}

extension IoxBleModule: CBPeripheralManagerDelegate {
    private class PartialGoData {
        var data: [UInt8] = []
        var expectedLength: Int = -1
        
        func isFull() -> Bool {
            if (data.count > expectedLength) {
                data = []
                expectedLength = -1
            }
            return data.count == expectedLength
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            break
        case .unsupported:
            if isStarted && startListener == nil {
                webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: new Error('BLE is unsupported') }"))
            }
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE is unsupported")))
            stop()
        case .unauthorized:
            if isStarted && startListener == nil {
                webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: new Error('BLE is unauthorized') }"))
            }
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE usage is unauthorized")))
            stop()
        case .resetting:
            break
        case .poweredOn:
            startServiceIfNotYet()
        case .poweredOff:
            if isStarted && startListener == nil {
                webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: new Error('BLE is power off state') }"))
            }
            callStartListener(result: Result.failure(GeotabDriveErrors.IoxBleError(error: "BLE is in Power off state")))
            stop()
        @unknown default:
            if isStarted && startListener == nil {
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
        isStarted = true
        
        // after reconnecting, we don't get didSubscribeTo again so we can assume it is already subscribed
        if self.central != nil {
            queue.isSuspended = false
            sendSyncMessage()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.central = central
        queue.isSuspended = false
        sendSyncMessage()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        self.central = nil
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for req in requests {
            guard let data = req.value, req.characteristic == writeChar, req.central == central else {
                continue
            }
            
            let operation = BlockOperation()
            let byteArray = [UInt8](data)
            operation.addExecutionBlock {
                guard byteArray.count > 0 else {
                    return
                }
                
                if byteArray == Messages.handshake {
                    self.sendHandshakeConfirmationMessage()
                    return
                }
                
                if byteArray == Messages.ack {
                    self.isConnected = true
                    return
                }
                
                if isGoDeviceData(byteArray) {
                    self.partialGoData = PartialGoData()
                    self.partialGoData.expectedLength = Int(byteArray[2]) + 6
                }
                self.partialGoData.data.append(contentsOf: byteArray)
                
                guard self.partialGoData.isFull() else {
                    return
                }
                
                do {
                    let message = try GoDeviceDataMessage(bytes: self.partialGoData.data)
                    let event = try self.transformer.transform(byteArray: message.data)
                    let deviceJson = String(data: try JSONEncoder().encode(event), encoding: .utf8)!
                    self.executer.run {
                        self.webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.godevicedata", params: "{ detail: \(deviceJson) }"))
                    }
                } catch (let error) {
                    self.executer.run {
                        self.webDriveDelegate.push(moduleEvent:  ModuleEvent(event: "ioxble.error", params: "{ detail: \"\(error.localizedDescription)\" }"))
                    }
                }
            }
            
            queue.addOperation(operation)
        }
    }
}
