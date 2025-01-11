class SpeechModule: Module {
    static let moduleName = "speech"
    fileprivate var speechEngine: SpeechEngine
    
    init() {
        speechEngine = RealSpeechEngine()
        super.init(name: SpeechModule.moduleName)
        functions.append(NativeSpeakFunction(module: self, speechEngine: SpeechEngineAdapter(module: self)))
    }
    
    func setSpeechEngine(speechEngine: SpeechEngine) {
        self.speechEngine = speechEngine
    }
}

class SpeechEngineAdapter: SpeechEngine {
    private weak var module: SpeechModule?
    
    init(module: SpeechModule) {
        self.module = module
    }
    
    func speak(text: String, rate: Float, language: String) {
        module?.speechEngine.speak(text: text, rate: rate, language: language)
    }
}
