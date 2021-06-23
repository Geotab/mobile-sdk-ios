//
//  NativeSpeakFunction.swift
//  GeotabDriveSDK
//
//  Created by Chet Chhom on 2020-01-20.
//
import Foundation

struct NativeSpeakArgument: Codable {
    let text: String
    let rate: Float
    let lang: String
}

class NativeSpeakFunction: ModuleFunction {
    private let module: SpeechModule
    init(module: SpeechModule) {
        self.module = module
        super.init(module: module, name: "nativeSpeak")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        
        guard argument != nil, JSONSerialization.isValidJSONObject(argument!), let data = try? JSONSerialization.data(withJSONObject: argument!) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        guard let arg = try? JSONDecoder().decode(NativeSpeakArgument.self, from: data) else {
            jsCallback(Result.failure(GeotabDriveErrors.ModuleFunctionArgumentError))
            return
        }
        
        let text = arg.text
        // JS uses a rate from 0.1-10, where 1 is normal. iOS uses 0.1-1, where 0.5 is normal.
        let rate = arg.rate / 2 // This is an estimation, not a right transformation equation, needs to be addressed in the future.
        let lang = arg.lang
        
        module.speechEngine.speak(text: text, rate: rate, language: lang)
        jsCallback(Result.success("undefined"))
    }
}
