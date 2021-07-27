// Copyright © 2021 Geotab Inc. All rights reserved.

public protocol SpeechEngine {
    func speak(text: String, rate: Float, language: String)
}
