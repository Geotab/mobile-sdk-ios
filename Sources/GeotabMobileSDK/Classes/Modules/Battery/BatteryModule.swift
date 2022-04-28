import UIKit

protocol DeviceBatteryStateAdapter: AnyObject {

    var isBatteryMonitoringEnabled: Bool { get set }

    var batteryState: UIDevice.BatteryState { get }

    var batteryLevel: Float { get }
}

class BatteryModule: Module {
    private let adapter: DeviceBatteryStateAdapter
    private let webDriveDelegate: WebDriveDelegate
    var started: Bool {
        return adapter.isBatteryMonitoringEnabled
    }
    var isCharging = false
    var batteryLevel = 0
    init(webDriveDelegate: WebDriveDelegate, adapter: DeviceBatteryStateAdapter = UIDevice.current) {
        self.webDriveDelegate = webDriveDelegate
        self.adapter = adapter
        super.init(name: "battery")
        monitorBatteryStatus()
        updateState()
    }
    func monitorBatteryStatus() {
        adapter.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryStatusDidChange), name: UIDevice.batteryStateDidChangeNotification, object: UIDevice.current)
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryStatusDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: UIDevice.current)
    }
    
    func updateState() {
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
        updateState()
        webDriveDelegate.push(moduleEvent: ModuleEvent(event: "batterystatus", params: "{ \"detail\": { isPlugged: \(isCharging), level: \(batteryLevel) } }")) { _ in }
    }
}

extension UIDevice: DeviceBatteryStateAdapter { }
