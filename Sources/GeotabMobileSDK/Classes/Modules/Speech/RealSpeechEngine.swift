import AVFoundation

class RealSpeechEngine: SpeechEngine {
    let synthesizer = AVSpeechSynthesizer()

    public func speak(text: String, rate: Float = 0.5, language: String = "en-US") {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
}
