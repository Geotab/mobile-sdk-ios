//
//  ScriptInjectable.swift
//  
//
//  Created by vlad.paianu on 02.08.2023.
//

import Foundation
import WebKit

public protocol ScriptInjectable {
    var source: String { get }
    var injectionTime: WKUserScriptInjectionTime { get }
    var messageHandlerName: String { get }
}
