import Foundation
import CoreBluetooth

protocol IoxClientDelegate: AnyObject {
    func clientDidStart(_ client: IoxClient, error: GeotabDriveErrors?)
    func clientDidStopUnexpectedly(_ client: IoxClient, error: GeotabDriveErrors)
    func clientDidReceiveEvent(_ client: IoxClient, event: DeviceEvent?, error: GeotabDriveErrors?)
    func clientDidDisconnect(_ client: IoxClient, error: GeotabDriveErrors?)
    func clientDidUpdateState(_ client: IoxClient, state: IoxClientState)
}

enum IoxClientState {
    case idle
    case advertising
    case syncing
    case handshaking
    case connected
}

protocol IoxClient {
    var state: IoxClientState { get }
    var delegate: IoxClientDelegate? { get set }
    func start(serviceId: String)
    func stop()
}

/// :nodoc:
class DefaultIoxClient: NSObject, IoxClient {

    @TaggedLogger("DefaultIoxClient")
    private var logger
    
    private let executer: AsyncMainExecuterAdapter
    private let queue: OperationQueue
    private let transformer: DeviceEventTransformer = DeviceEventTransformer()
    
    var state: IoxClientState = .idle {
        didSet {
            delegate?.clientDidUpdateState(self, state: state)
            $logger.debug("State updated to \(String(describing: state))")
        }
    }
    private var isStarted: Bool {
        if case .idle = state {
            return false
        }
        return true
    }
    private var isConnected: Bool {
        if case .connected = state {
            return true
        }
        return false
    }
    
    private var partialGoData: PartialGoData = PartialGoData()
    
    private lazy var peripheralManager: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    private var central: CBCentral?
    
    private let notifyCharId = CBUUID(nsuuid: UUID(uuidString: "430F2EA3-C765-4051-9134-A341254CFD00")!)
    private let writeCharId = CBUUID(nsuuid: UUID(uuidString: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")!)
    private lazy var notifyChar = CBMutableCharacteristic(type: notifyCharId, properties: [.notify, .read], value: nil, permissions: [.readable, .writeable])
    private lazy var writeChar = CBMutableCharacteristic(type: writeCharId, properties: [.write], value: nil, permissions: [.writeable])
    private lazy var descriptor = CBMutableDescriptor(type: CBUUID(string: "2902"), value: nil)
    
    weak var delegate: IoxClientDelegate?
    private var uuid: UUID?
    
    override convenience init() {
        self.init(executer: MainExecuter(), queue: OperationQueue())
    }
    
    // init for testing
    init(executer: AsyncMainExecuterAdapter, queue: OperationQueue) {
        self.executer = executer
        self.queue = queue
        self.queue.qualityOfService = .userInitiated
        self.queue.maxConcurrentOperationCount = 1
    }
    
    func start(serviceId: String) {
        
        guard !isStarted else {
            delegate?.clientDidStart(self, error: .IoxBleError(error: IoxBleError.bleServiceAlreadyStarted.rawValue))
            return
        }
        
        guard let uuid = UUID(uuidString: serviceId) else {
            delegate?.clientDidStart(self, error: .IoxBleError(error: "\(serviceId) is not an UUID"))
            return
        }
        self.uuid = uuid
        
        switch peripheralManager.state {
        case .poweredOff:
            delegate?.clientDidStart(self, error: .IoxBleError(error: IoxBleError.blePoweredOffError.rawValue))
            stop()
        case .unauthorized:
            delegate?.clientDidStart(self, error: .IoxBleError(error: IoxBleError.bleUnauthorizedError.rawValue))
            stop()
        case .unsupported:
            delegate?.clientDidStart(self, error: .IoxBleError(error: IoxBleError.bleUnsupportedError.rawValue))
            stop()
        case .poweredOn:
            startServiceIfNotYet()
        default:
            if authStateDeniedOrRestricted() {
                delegate?.clientDidStart(self, error: .IoxBleError(error: IoxBleError.blePoweredOffError.rawValue))
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
        state = .idle
    }
    
    private func startServiceIfNotYet() {
        guard !isStarted else {
            delegate?.clientDidStart(self, error: .IoxBleError(error: IoxBleError.bleServiceAlreadyStarted.rawValue))
            return
        }
        
        guard let uuid = uuid else {
            delegate?.clientDidStart(self, error: .IoxBleError(error: "UUID not set"))
            return
        }
        
        let serviceId = CBUUID(nsuuid: uuid)
        let service = CBMutableService(type: serviceId, primary: true)
        notifyChar.descriptors?.append(descriptor)
        service.characteristics = [notifyChar, writeChar]

        // here we are assuming only one service is going to be used
        peripheralManager.removeAllServices()
        peripheralManager.add(service)
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "ioxble",
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
}

// MARK: - Protocol
/// :nodoc:
extension DefaultIoxClient {
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

// MARK: - CBPeripheralManagerDelegate
/// :nodoc:
extension DefaultIoxClient: CBPeripheralManagerDelegate {
    private class PartialGoData {
        var data: [UInt8] = []
        var expectedLength: Int = -1
        
        func isFull() -> Bool {
            if data.count > expectedLength {
                data = []
                expectedLength = -1
            }
            return data.count == expectedLength
        }
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
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            break
        case .unsupported:
            let error = GeotabDriveErrors.IoxBleError(error: IoxBleError.bleUnsupportedError.rawValue)
            if isStarted {
                // this should not be possible
                delegate?.clientDidStopUnexpectedly(self, error: error)
            } else {
                delegate?.clientDidStart(self, error: error)
            }
            stop()
        case .unauthorized:
            let error = GeotabDriveErrors.IoxBleError(error: IoxBleError.blePoweredOffError.rawValue)
            if isStarted {
                delegate?.clientDidStopUnexpectedly(self, error: error)
            } else {
                delegate?.clientDidStart(self, error: error)
            }
            stop()
        case .resetting:
            break
        case .poweredOn:
            startServiceIfNotYet()
        case .poweredOff:
            let error = GeotabDriveErrors.IoxBleError(error: IoxBleError.blePoweredOffError.rawValue)
            if isStarted {
                delegate?.clientDidStopUnexpectedly(self, error: error)
            } else {
                delegate?.clientDidStart(self, error: error)
            }
            stop()
        @unknown default:
            let error = GeotabDriveErrors.IoxBleError(error: "Unknown error")
            if isStarted {
                delegate?.clientDidStopUnexpectedly(self, error: error)
            } else {
                delegate?.clientDidStart(self, error: error)
            }
            stop()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            $logger.debug("CBPeripheralManager error adding service \(error.localizedDescription)")
            delegate?.clientDidStart(self, error: .IoxBleError(error: "BLE failed adding the service"))
            stop()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            $logger.debug("CBPeripheralManager error starring advertising \(error.localizedDescription)")
            delegate?.clientDidStart(self, error: .IoxBleError(error: "BLE failed advertising the service"))
            stop()
            return
        }

        delegate?.clientDidStart(self, error: nil)
        state = .advertising
        
        // after reconnecting, we don't get didSubscribeTo again so we can assume it is already subscribed
        if self.central != nil {
            queue.isSuspended = false
            sendSyncMessage()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        $logger.debug("CBPeripheralManager characteristic subscribed to")
        self.central = central
        queue.isSuspended = false
        state = .syncing
        sendSyncMessage()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        $logger.debug("CBPeripheralManager characteristic unsubscribed from")
        state = .advertising
        self.central = nil
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        $logger.debug("CBPeripheralManager received write")
        
        // didReceiveWrite must be responded only once for a sequences of requests
        if let request = requests.first {
            peripheral.respond(to: request, withResult: .success)
        }
        
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
                    self.$logger.debug("CBPeripheralManager setting to handshaking after handshake message")
                    self.state = .handshaking
                    self.sendHandshakeConfirmationMessage()
                    return
                }
                
                if byteArray == Messages.ack {
                    self.$logger.debug("CBPeripheralManager setting to connected after ack message")
                    self.state = .connected
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
                    let event = try self.transformer.transform(byteArray: Data(message.payload))
                    self.executer.run { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.clientDidReceiveEvent(self, event: event, error: nil)
                    }
                } catch {
                    self.$logger.debug("CBPeripheralManager could not transform message. Error: \(error.localizedDescription)")
                    self.executer.run { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.clientDidReceiveEvent(self,
                                                             event: nil,
                                                             error: .IoxEventParsingError(error: "Could not decode Go device message"))
                    }
                }
            }
            
            queue.addOperation(operation)
        }
    }
}
