import AVFoundation

class RealSpeechEngine: SpeechEngine {
    let synthesizer = AVSpeechSynthesizer()

    public func speak(text: String, rate: Float = 0.5, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
}
