//
//  SpeechEngine.swift
//  GeotabDriveSDK
//
//  Created by Chet Chhom on 2020-01-20.
//

public protocol SpeechEngine {
    func speak(text: String, rate: Float, language: String)
}
