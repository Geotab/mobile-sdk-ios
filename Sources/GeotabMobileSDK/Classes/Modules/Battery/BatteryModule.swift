import UIKit

protocol DeviceBatteryStateAdapter: AnyObject {
    var isBatteryMonitoringEnabled: Bool { get set }
    var batteryState: UIDevice.BatteryState { get }
    var batteryLevel: Float { get }
}

class BatteryModule: Module {
    static let moduleName = "battery"

    private weak var adapter: DeviceBatteryStateAdapter?
    private weak var scriptGateway: ScriptGateway?
    var started: Bool {
        guard let adapter else { return false }
        return adapter.isBatteryMonitoringEnabled
    }
    var isCharging = false
    var batteryLevel = 0
    init(scriptGateway: ScriptGateway, adapter: DeviceBatteryStateAdapter = UIDevice.current) {
        self.scriptGateway = scriptGateway
        self.adapter = adapter
        super.init(name: BatteryModule.moduleName)
        monitorBatteryStatus()
        updateState()
    }
    func monitorBatteryStatus() {
        guard let adapter else { return }
        adapter.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryStatusDidChange), name: UIDevice.batteryStateDidChangeNotification, object: UIDevice.current)
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryStatusDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: UIDevice.current)
    }
    
    func updateState() {
        guard let adapter else { return }
        switch adapter.batteryState {
        case .full, .charging:
            isCharging = true
        case .unplugged, .unknown:
            isCharging = false
        @unknown default:
            fatalError()
        }
        if adapter.batteryLevel == -1 {
            batteryLevel = 0
        } else {
            batteryLevel = Int(adapter.batteryLevel * 100)
        }
    }

    @objc private func batteryStatusDidChange(notification: NSNotification) {
        guard let scriptGateway else { return }
        updateState()
        scriptGateway.push(moduleEvent: ModuleEvent(event: "batterystatus", params: "{ \"detail\": { \"isPlugged\": \(isCharging), \"level\": \(batteryLevel) } }")) { _ in }
    }
}

extension UIDevice: DeviceBatteryStateAdapter { }
