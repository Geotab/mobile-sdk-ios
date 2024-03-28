import Foundation
import CoreBluetooth

enum IoxBleError: String {
    case blePoweredOffError = "BLE is in the power off state."
    case bleUnauthorizedError = "BLE usage is unauthorized."
    case bleUnsupportedError = "BLE is unsupported."
    case bleServiceAlreadyStarted = "Another service has already been started."
}

class IoxBleModule: Module {
    static let moduleName = "ioxble"
    
    enum State: Int {
        case idle = 0, advertising, syncing, handshaking, connected, disconnecting
    }

    private static let errorEventName = "ioxble.error"
    private static let deviceEventName = "ioxble.godevicedata"
    private static let stateEventName = "ioxble.state"
    private static let statePropertyName = "state"
    
    private let scriptGateway: ScriptGateway
    private var startListener: ((Result<String, Error>) -> Void)?
    private var client: IoxClient
    private let executer: AsyncMainExecuterAdapter

    var ioxDeviceEventCallback: IOXDeviceEventCallbackType?
    
    convenience init(scriptGateway: ScriptGateway) {
        let ex = MainExecuter()
        self.init(scriptGateway: scriptGateway,
                  executer: ex,
                  client: DefaultIoxClient(executer: ex, queue: OperationQueue()))
    }
    
    // init for testing
    init(scriptGateway: ScriptGateway, executer: AsyncMainExecuterAdapter, client: IoxClient) {
        self.scriptGateway = scriptGateway
        self.executer = executer
        self.client = client
        super.init(name: IoxBleModule.moduleName)
        functions.append(StartIoxBleFunction(module: self))
        functions.append(StopIoxBleFunction(module: self))
            
        self.client.delegate = self
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        scripts += updateStatePropertyScript(state: client.state)
        return scripts
    }

    func callStartListener(result: Result<String, Error>) {
        guard startListener != nil else {
            return
        }
        startListener!(result)
        startListener = nil
    }
    
    func start(serviceId: String, _ jsCallback: @escaping (Result<String, Error>) -> Void) {
        guard startListener == nil else {
            jsCallback(Result.failure(GeotabDriveErrors.IoxBleError(error: "One call at a time only")))
            return
        }
        startListener = jsCallback
        client.start(serviceId: serviceId)
    }
    
    func stop() {
        client.stop()
    }
}

extension IoxBleModule: IoxClientDelegate {
    
    private func updateStatePropertyScript(state: IoxClientState) -> String {
        return """
        if (\(Module.geotabModules) !== undefined && \(Module.geotabModules).\(name) !== undefined) {
            window.\(Module.geotabModules).\(name).\(IoxBleModule.statePropertyName) = \(state.toJSState().rawValue);
        }
        """
    }
    
    private func stateEventDetailJson(state: IoxClientState) -> String {
        return """
        { "\(IoxBleModule.statePropertyName)": \(state.toJSState().rawValue) }
        """
    }

    private func fireEvent(name: String, detailValue: String) {
        scriptGateway.push(moduleEvent: ModuleEvent(event: name,
                                                    params: "{ \"detail\": \(detailValue) }")) { _ in }
    }
    
    private func fireErrorEvent(error: GeotabDriveErrors) {
        fireEvent(name: IoxBleModule.errorEventName, detailValue: "\"\(error.localizedDescription)\"")
        ioxDeviceEventCallback?(.failure(error))
    }
    
    func clientDidUpdateState(_ client: IoxClient, state: IoxClientState) {
        executer.run { [weak self] in
            guard let self = self else { return }
            self.scriptGateway.evaluate(script: self.updateStatePropertyScript(state: state)) { _ in }
            self.fireEvent(name: IoxBleModule.stateEventName, detailValue: self.stateEventDetailJson(state: state))
        }
    }
    
    func clientDidStart(_ client: IoxClient, error: GeotabDriveErrors?) {
        if let error = error {
            fireErrorEvent(error: error)
            callStartListener(result: Result.failure(error))
        } else {
            callStartListener(result: Result.success("undefined"))
        }
    }
    
    func clientDidStopUnexpectedly(_ client: IoxClient, error: GeotabDriveErrors) {
        fireErrorEvent(error: error)
    }
    
    func clientDidReceiveEvent(_ client: IoxClient, event: DeviceEvent?, error: GeotabDriveErrors?) {
        if let error = error {
            fireErrorEvent(error: error)
        } else if let event = event,
                  let eventData = try? JSONEncoder().encode(event),
                  let deviceJson = String(data: eventData, encoding: .utf8) {
            fireEvent(name: IoxBleModule.deviceEventName, detailValue: deviceJson)
            let ioxBLEDeviceEvent = IOXDeviceEvent(type: 0, deviceEvent: event)
            ioxDeviceEventCallback?(.success(ioxBLEDeviceEvent))
        } else {
            fireErrorEvent(error: .IoxEventParsingError(error: "Could not decode event"))
        }
    }
    
    func clientDidDisconnect(_ client: IoxClient, error: GeotabDriveErrors?) {
    }
}

extension IoxClientState {
    func toJSState() -> IoxBleModule.State {
        switch self {
        case .idle:
            return .idle
        case .advertising:
            return .advertising
        case .syncing:
            return .syncing
        case .handshaking:
            return .handshaking
        case .connected:
            return .connected
        }
    }
}
