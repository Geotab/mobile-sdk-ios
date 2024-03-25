class DeviceModule: Module {
    static let moduleName = "device"
    static let device = Device()
    let scriptGateway: ScriptGateway
    
    init(scriptGateway: ScriptGateway) {
        self.scriptGateway = scriptGateway
        super.init(name: DeviceModule.moduleName)
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
        return scripts
    }
}
