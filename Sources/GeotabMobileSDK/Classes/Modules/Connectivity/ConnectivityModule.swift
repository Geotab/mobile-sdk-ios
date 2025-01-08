import CoreTelephony
import Reachability

protocol NetworkReachability: AnyObject {
    var whenReachable: Reachability.NetworkReachable? { get set }
    var whenUnreachable: Reachability.NetworkUnreachable? { get set }
    var connection: Reachability.Connection { get }

    func startNotifier() throws
    func stopNotifier()
    
    var currentRadioAccessTechnology: String? { get }
}

class ConnectivityModule: Module {
    private static let moduleName = "connectivity"

    private weak var scriptGateway: ScriptGateway?
    private let reachability: NetworkReachability?
    var started = false
    init(scriptGateway: ScriptGateway,
         reachability: NetworkReachability? = try? Reachability(notificationQueue: .global())) {
        self.scriptGateway = scriptGateway
        self.reachability = reachability
        super.init(name: ConnectivityModule.moduleName)
        functions.append(StartFunction(starter: self))
        functions.append(StopFunction(stopper: self))
        
        self.reachability?.whenReachable = { [weak self] _ in
            self?.updateState(online: true)
            self?.signalConnectivityEvent(online: true)
        }
        self.reachability?.whenUnreachable = { [weak self] _ in
            self?.updateState(online: false)
            self?.signalConnectivityEvent(online: false)
        }
    }
    
    func signalConnectivityEvent(online: Bool) {
        guard started,
              let json = stateJson(online: online) else {
            return
        }
        scriptGateway?.push(moduleEvent: ModuleEvent(event: "connectivity", params: "{ \"detail\": \(json) }")) { _ in }
    }
    
    func stateJson(online: Bool) -> String? {
        let onlineParams = ConnectivityState(online: online, type: self.getNetworkType().rawValue)
        return toJson(onlineParams)
    }
    
    func updateState(online: Bool) {
        guard started,
              let json = stateJson(online: online) else {
            return
        }
        evaluateScript(json: json)
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()

        let type = self.getNetworkType()
        if let json = stateJson(online: type != .NONE && type != .UNKNOWN) {
            scripts +=
                """
                    if (window.\(Module.geotabModules) != null && window.\(Module.geotabModules).\(name) != null) {
                        window.\(Module.geotabModules).\(name).state = \(json);
                    }
                """
        }
        return scripts
    }
    
    func getNetworkType() -> ConnectivityType {
        guard let reachability = reachability else { return .UNKNOWN }
        switch reachability.connection {
        case .none:     return .NONE
        case .wifi: return .WIFI
        case .cellular: return getWWANNetworkType()
        case .unavailable: return .NONE
        }
    }
    
    func getWWANNetworkType() -> ConnectivityType {
        guard let currentRadioAccessTechnology = reachability?.currentRadioAccessTechnology else { return .UNKNOWN }
        switch currentRadioAccessTechnology {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return .CELL_2G
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .CELL_3G
        case CTRadioAccessTechnologyLTE:
            return .CELL_4G
        default:
            return .CELL
        }
    }
    
    func evaluateScript(json: String) {
        let script =
            """
                if (window.\(Module.geotabModules) != null && window.\(Module.geotabModules).\(name) != null) {
                    window.\(Module.geotabModules).\(name).state = \(json);
                }
            """
        scriptGateway?.evaluate(script: script) { _ in }
    }
}

// MARK: - ConnectivityStarting
extension ConnectivityModule: ConnectivityStarting {
    func start() -> Bool {
        do {
            try reachability?.startNotifier()
            started = true
            return true
        } catch {
            return false
        }
    }
}

// MARK: - ConnectivityStopping
extension ConnectivityModule: ConnectivityStopping {
    func stop() {
        reachability?.stopNotifier()
        started = false
    }
}

// MARK: - Helper extensions

extension Reachability: NetworkReachability {
    var currentRadioAccessTechnology: String? {
        CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?.first?.value
    }
}
