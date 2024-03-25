class SpeechModule: Module {
    static let moduleName = "speech"

    var speechEngine: SpeechEngine!
    
    init() {
        self.speechEngine = RealSpeechEngine()
        super.init(name: SpeechModule.moduleName)
        functions.append(NativeSpeakFunction(module: self))
    }
    
    func setSpeechEngine(speechEngine: SpeechEngine) {
        self.speechEngine = speechEngine
    }
}
