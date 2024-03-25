import UIKit

protocol BackgroundAudioPlaying {
    func play() -> Bool
    var isPlaying: Bool { get }
    func stop()
}

typealias BackgroundAudioFactory = (AppModule) -> BackgroundAudioPlaying?
typealias ApplicationState = () -> UIApplication.State

class AppModule: Module {
    
    static let moduleName = "app"
    private let scriptGateway: ScriptGateway
    private let appLogEventSource: AppLogEventSource
    let options: MobileSdkOptions
    
    var lastServerAddressUpdated: LastServerAddressUpdatedCallbackType?
    var keepAlive = "{}"
    
    private var backgroundAudioPlayer: BackgroundAudioPlaying?
    private let backgroundAudioFactory: BackgroundAudioFactory
    private let applicationState: ApplicationState

    init(scriptGateway: ScriptGateway,
         options: MobileSdkOptions,
         backgroundAudioFactory: @escaping BackgroundAudioFactory = defaultBackgroundAudioFactory,
         applicationState: @escaping ApplicationState = { UIApplication.shared.applicationState }) {
        self.scriptGateway = scriptGateway
        self.options = options
        self.backgroundAudioFactory = backgroundAudioFactory
        self.applicationState = applicationState
        appLogEventSource = AppLogEventSource(scriptGateway: scriptGateway)
        super.init(name: AppModule.moduleName)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationFinishedLaunching),
                                               name: UIApplication.didFinishLaunchingNotification,
                                               object: nil)
        functions.append(UpdateLastServerFunction(module: self))
        functions.append(ClearWebViewCacheFunction(module: self))
    }
    
    func configure() throws {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(backgroundModeChanged),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(backgroundModeChanged),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        backgroundAudioPlayer = backgroundAudioFactory(self)
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        var background = false
        let state = applicationState()
        if state == .background || state == .inactive {
            background = true
        } else if state == .active {
            background = false
        }
        scripts +=
            """
                if (window.\(Module.geotabModules) != null && window.\(Module.geotabModules).\(name) != null) {
                    window.\(Module.geotabModules).\(name).background = \(background);
                    window.\(Module.geotabModules).\(name).keepAlive = \(keepAlive);
                }
            """
        return scripts
    }
    
    @objc
    func applicationFinishedLaunching(notification: NSNotification) {
        do {
            try configure()
        } catch {
            fireBackgroundFailureEvent(error: "Keep alive initialization failed")
        }
    }
    
    @objc
    func backgroundModeChanged(notification: NSNotification) {

        var isBackground: Bool?
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            isBackground = true
            if let backgroundAudioPlayer,
               !backgroundAudioPlayer.play() {
                fireBackgroundFailureEvent(error: "Failed enabling Keep alive")
                return
            }
        case UIApplication.willEnterForegroundNotification:
            isBackground = false
            if let backgroundAudioPlayer,
               backgroundAudioPlayer.isPlaying {
                backgroundAudioPlayer.stop()
            }
        default:
            break
        }
        guard let background = isBackground else {
            return
        }
        
        fireBackgroundChangedEvent(background: background)
    }
    
    func fireBackgroundChangedEvent(background: Bool) {
        keepAlive = "{}"
        evaluateScript(background: background)
        scriptGateway.push(moduleEvent: ModuleEvent(event: "app.background", params: "{ \"detail\": \(background) }")) { _ in }
    }
    
    func fireBackgroundFailureEvent(error: String) {
        let background = applicationState() == .active ? false : true
        keepAlive = "{ error: \"\(error)\" }"
        evaluateScript(background: background)
        scriptGateway.push(moduleEvent: ModuleEvent(event: "app.background.keepalive", params: "{ \"detail\": { \"error\": \"\(error)\" } }")) { _ in }
    }
    
    func evaluateScript(background: Bool) {
        let script =
            """
                if (window.\(Module.geotabModules) != null && window.\(Module.geotabModules).\(name) != null) {
                    window.\(Module.geotabModules).\(name).background = \(background);
                    window.\(Module.geotabModules).\(name).keepAlive = \(keepAlive);
                }
            """
        scriptGateway.evaluate(script: script) { _ in }
    }
    
}

private func defaultBackgroundAudioFactory(_ appModule: AppModule) -> BackgroundAudioPlaying? {
    BackgroundAudioPlayer(appModule: appModule)
}
