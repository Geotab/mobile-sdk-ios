//
//  SpeechModule.swift
//  GeotabDriveSDK
//
//  Created by Chet Chhom on 2020-01-20.
//

class SpeechModule: Module {
    var speechEngine: SpeechEngine!
    
    init() {
        self.speechEngine = RealSpeechEngine()
        super.init(name: "speech")
        functions.append(NativeSpeakFunction(module: self))
    }
    
    func setSpeechEngine(speechEngine: SpeechEngine) {
        self.speechEngine = speechEngine
    }
}
