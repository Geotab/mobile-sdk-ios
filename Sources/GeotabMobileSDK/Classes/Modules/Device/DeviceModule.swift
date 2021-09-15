


class DeviceModule: Module {
    static let device = Device()
    let webDriveDelegate: WebDriveDelegate
    
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        super.init(name: "device")
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
                
        scripts += """
        window.\(Module.geotabModules).\(name).platform = "\(DeviceModule.device.platform)";
        
        window.\(Module.geotabModules).\(name).manufacturer = "\(DeviceModule.device.manufacturer)";

        window.\(Module.geotabModules).\(name).appId = "\(DeviceModule.device.appId)";

        window.\(Module.geotabModules).\(name).appName = "\(DeviceModule.device.appName)";
        
        window.\(Module.geotabModules).\(name).version = "\(DeviceModule.device.version)";

        window.\(Module.geotabModules).\(name).sdkVersion = "\(DeviceModule.device.sdkVersion)";
        
        window.\(Module.geotabModules).\(name).model = "\(DeviceModule.device.model)";
        
        window.\(Module.geotabModules).\(name).uuid = "\(DeviceModule.device.uuid)";

        window.device = window.\(Module.geotabModules).\(name);
        """
        return scripts;
    }
    
    func geotabDriveReady() {
        webDriveDelegate.push(moduleEvent: ModuleEvent(event: "sdkready", params: "undefined"))
    }
}
