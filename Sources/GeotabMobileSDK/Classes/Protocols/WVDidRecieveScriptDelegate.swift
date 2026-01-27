//
//  WVDidRecieveScriptDelegate.swift
//  GeotabMobileSDK
//
//  Created by Abdelrhman Eliwa on 18/12/2025.
//

public import WebKit

public protocol WVDidRecieveScriptDelegate: AnyObject {
    func didReceive(scriptMessage: WKScriptMessage)
}

public extension WVDidRecieveScriptDelegate {
    func didReceive(scriptMessage: WKScriptMessage) { }
}
