//
//  WebInteractionDelegate.swift
//  
//
//  Created by vlad.paianu on 02.08.2023.
//

import Foundation
import WebKit

/**
 Protocol to handle specific interactions within a WebView.
 */
public protocol WebInteractionDelegate: AnyObject {
    /**
     Called to determine the navigation policy for a given navigation action.
     
     - Parameter navigationAction: The navigation action that will be taken.
     */
    func onDecidePolicy(navigationAction: WKNavigationAction)

    /**
     Called when a script message is received from a WebView.
     
     - Parameter scriptMessage: The script message that was received.
     */
    func didReceive(scriptMessage: WKScriptMessage)
}

public extension WebInteractionDelegate {
    func onDecidePolicy(navigationAction: WKNavigationAction) {}
    func didReceive(scriptMessage: WKScriptMessage) {}
}
