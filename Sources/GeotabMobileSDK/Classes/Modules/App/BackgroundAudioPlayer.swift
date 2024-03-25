import AVFoundation
import CoreLocation

class BackgroundAudioPlayer: NSObject, BackgroundAudioPlaying {
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
    
    private weak var appModule: AppModule?
    private weak var audioSession: AVAudioSession?
    
    init(appModule: AppModule) {
        self.appModule = appModule
    }
    
    private func configureAudioSession() throws {
        
        guard audioPlayer != nil else {
            throw GeotabDriveErrors.AppModuleError(error: "init Audio Player failed")
        }
        
        audioSession = AVAudioSession.sharedInstance()
        try audioSession?.setActive(false)
        try audioSession?.setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)  // AVAudioSessionCategoryPlayback
        try audioSession?.setActive(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterrupt), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    @objc
    func audioSessionInterrupt() {
        guard let audioPlayer else {
            appModule?.fireBackgroundFailureEvent(error: "Keep alive initialization failed")
            return
        }
        appModule?.fireBackgroundChangedEvent(background: true)
        audioPlayer.play()
    }
    
    func play() -> Bool {
        let keepAliveMode = DriveSdkConfig.backgroundAudioKeepAliveMode
        guard keepAliveMode == .always ||
                (keepAliveMode == .whenNecessary && !CLLocationManager.isAuthorizedForAlways()) else {
            try? audioSession?.setActive(false)
            return true
        }
        
        guard let audioPlayer else {
            appModule?.fireBackgroundFailureEvent(error: "Keep alive initialization failed")
            return false
        }
        
        if audioSession == nil {
            do {
                try configureAudioSession()
            } catch {
                var errorDescription = "Keep alive initialization failed"
                if let geotabError = error as? GeotabDriveErrors,
                   let desc = geotabError.errorDescription {
                    errorDescription = desc
                }
                appModule?.fireBackgroundFailureEvent(error: errorDescription)
                return false
            }
        }
        return audioPlayer.play()
    }

    var isPlaying: Bool {
        guard let audioPlayer else {
            return false
        }
        return audioPlayer.isPlaying
    }
    
    func stop() {
        audioPlayer?.pause()
    }
}
