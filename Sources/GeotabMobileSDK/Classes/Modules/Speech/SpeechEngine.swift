/// :nodoc:
public protocol SpeechEngine: AnyObject {
    func speak(text: String, rate: Float, language: String)
}
