//
//  ScriptInjectable.swift
//  GeotabMobileSDK
//
//  Created by Abdelrhman Eliwa on 18/12/2025.
//

public import WebKit

public protocol ScriptInjectable {
    var source: String { get }
    var injectionTime: WKUserScriptInjectionTime { get }
    var messageHandlerName: String { get }
}
