import CoreTelephony
import Reachability

class ConnectivityModule: Module {
    let webDriveDelegate: WebDriveDelegate
    let reachability = try? Reachability()
    var started = false
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        super.init(name: "connectivity")
        functions.append(StartFunction(module: self))
        functions.append(StopFunction(module: self))
        
        reachability?.whenReachable = { _ in
            self.updateState(online: true)
            self.signalConnectivityEvent(online: true)
        }
        reachability?.whenUnreachable = { _ in
            self.updateState(online: false)
            self.signalConnectivityEvent(online: false)
        }
    }
    
    func signalConnectivityEvent(online: Bool) {
        guard let json = stateJson(online: online) else {
            return
        }
        webDriveDelegate.push(moduleEvent: ModuleEvent(event: "connectivity", params: "{ \"detail\": \(json) }")) { _ in }
    }
    
    func stateJson(online: Bool) -> String? {
        let onlineParams = ConnectivityState(online: online, type: self.getNetworkType().rawValue)
        return toJson(onlineParams)
    }
    
    func updateState(online: Bool) {
        if let json = stateJson(online: online) {
            let script = "window.\(Module.geotabModules).\(name).state = \(json);"
            webDriveDelegate.evaluate(script: script) { _ in }
        }
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()

        let type = self.getNetworkType()
        if let json = stateJson(online: type != .NONE && type != .UNKNOWN) {
            scripts += """
            window.\(Module.geotabModules).\(name).state = \(json);
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
        guard let currentRadioAccessTechnology = CTTelephonyNetworkInfo().currentRadioAccessTechnology else { return .UNKNOWN }
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
}
