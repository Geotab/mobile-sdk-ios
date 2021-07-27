// Copyright © 2021 Geotab Inc. All rights reserved.

import AVFoundation

class RealSpeechEngine: SpeechEngine {
    public func speak(text: String, rate: Float = 0.5, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
