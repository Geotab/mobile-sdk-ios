//
//  UIViewController-Extension.swift
//  
//
//  Created by vlad.paianu on 02.08.2023.
//

import UIKit

extension UIViewController {
    var isPresentInViewHierarchy: Bool {
        return isViewLoaded && view.window != nil
    }
}
