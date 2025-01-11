import Foundation

struct NativeSpeakArgument: Codable {
    let text: String
    let rate: Float?
    let lang: String?
}

class NativeSpeakFunction: ModuleFunction {
    private static let functionName: String = "nativeSpeak"
    private let speechEngine: SpeechEngine
    init(module: SpeechModule, speechEngine: SpeechEngine) {
        self.speechEngine = speechEngine
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        guard let arg = validateAndDecodeJSONObject(argument: argument, jsCallback: jsCallback, decodeType: NativeSpeakArgument.self) else { return }
        
        let text = arg.text
        // JS uses a rate from 0.1-10, where 1 is normal. iOS uses 0.1-1, where 0.5 is normal.
        let rate = (arg.rate ?? 1.0) / 2 // This is an estimation, not a right transformation equation, needs to be addressed in the future.
        let lang = arg.lang ?? "en-US"
        
        speechEngine.speak(text: text, rate: rate, language: lang)
        jsCallback(Result.success("undefined"))
    }
}
