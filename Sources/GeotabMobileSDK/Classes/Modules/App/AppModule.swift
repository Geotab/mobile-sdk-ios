import Foundation
import UIKit
import AVFoundation

class AppModule: Module {
    let webDriveDelegate: WebDriveDelegate
    let appLogEventSource: AppLogEventSource
    var lastServerAddressUpdated: LastServerAddressUpdatedCallbackType?
    var keepAlive = "{}"
    
    private lazy var appBeep: URL? = {        
        guard let path = Bundle.module.path(forResource: "appbeep", ofType: "wav") else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }()
    
    private lazy var audioPlayer: AVAudioPlayer? = {
        guard let beepUrl = appBeep else {
            return nil
        }
        guard let audioPlayer = try? AVAudioPlayer(contentsOf: beepUrl, fileTypeHint: AVFileType.wav.rawValue) else {
            return nil
        }
        audioPlayer.volume = 0
        audioPlayer.numberOfLoops = -1
        return audioPlayer
    }()
    
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        appLogEventSource = AppLogEventSource(webDriveDelegate: webDriveDelegate)
        super.init(name: "app")
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationFinishedLaunching), name: UIApplication.didFinishLaunchingNotification, object: nil)
        functions.append(UpdateLastServerFunction(module: self))
    }
    
    func configureAudioSession() throws {
        
        guard audioPlayer != nil else {
            throw GeotabDriveErrors.AppModuleError(error: "init Audio Player failed")
        }
        
        let session = AVAudioSession.sharedInstance()
        try session.setActive(false)
        try session.setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)  // AVAudioSessionCategoryPlayback
        try session.setActive(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.backgroundModeChanged), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.backgroundModeChanged), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioSessionInterrupt), name: AVAudioSession.interruptionNotification, object: nil)
        
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        var background = false
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            background = true
        } else if state == .active {
            background = false
        }
        scripts += """
        window.\(Module.geotabModules).\(name).background = \(background);
        window.\(Module.geotabModules).\(name).keepAlive = \(keepAlive);
        """
        return scripts
    }
    
    @objc public func applicationFinishedLaunching(notification: NSNotification) {
        do {
            try configureAudioSession()
        } catch {
            fireBackgroundFailureEvent(error: "Keep alive initialization failed")
        }
    }
    
    @objc public func backgroundModeChanged(notification: NSNotification) {
        guard let player = audioPlayer else {
            fireBackgroundFailureEvent(error: "Keep alive initialization failed")
            return
        }
        var isBackground: Bool?
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            isBackground = true
            if !player.play() {
                fireBackgroundFailureEvent(error: "Failed enabling Keep alive")
                return
            }
        case UIApplication.willEnterForegroundNotification:
            isBackground = false
            if player.isPlaying {
                player.pause()
            }
        default:
            break
        }
        guard let background = isBackground else {
            return
        }
        
        fireBackgroundChangedEvent(background: background)
    }
    
    @objc func audioSessionInterrupt() {
        guard let player = audioPlayer else {
            fireBackgroundFailureEvent(error: "Keep alive initialization failed")
            return
        }
        fireBackgroundChangedEvent(background: true)
        player.play()
    }
    
    func fireBackgroundChangedEvent(background: Bool) {
        var script = "window.\(Module.geotabModules).\(name).background = \(background);"
        keepAlive = "{}"
        script += "window.\(Module.geotabModules).\(name).keepAlive = \(keepAlive);"
        webDriveDelegate.evaluate(script: script) { _ in }
        webDriveDelegate.push(moduleEvent: ModuleEvent(event: "app.background", params: "{ \"detail\": \(background) }")) { _ in }
    }
    func fireBackgroundFailureEvent(error: String) {
        let background = UIApplication.shared.applicationState == .active ? false : true
        var script = "window.\(Module.geotabModules).\(name).background = \(background);"
        keepAlive = "{ error: \"\(error)\" }"
        script += "window.\(Module.geotabModules).\(name).keepAlive = \(keepAlive);"
        webDriveDelegate.evaluate(script: script) { _ in }
        webDriveDelegate.push(moduleEvent: ModuleEvent(event: "app.background.keepalive", params: "{ \"detail\": { \"error\": \"\(error)\" } }")) { _ in }
    }
    
}
