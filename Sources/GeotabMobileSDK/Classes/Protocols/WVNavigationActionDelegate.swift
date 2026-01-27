//
//  WVNavigationActionDelegate.swift
//  GeotabMobileSDK
//
//  Created by Abdelrhman Eliwa on 18/12/2025.
//

public import WebKit

public protocol WVNavigationActionDelegate: AnyObject {
    func onDecidePolicy(navigationAction: WKNavigationAction)
}

public extension WVNavigationActionDelegate {
    func onDecidePolicy(navigationAction: WKNavigationAction) { }
}
