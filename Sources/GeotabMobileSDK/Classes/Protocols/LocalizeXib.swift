//
//  LocalizeXib.swift
//  GeotabMobileSDK
//
//  Created by Anubhav Saini on 2020-12-03.
//
import UIKit

protocol LocalizeXib {
    var setKey: String? { get set }
}

func languageBundle() -> Bundle? {
    var lang = NSLocale.preferredLanguages.first ?? "en";
    if let path = Bundle.module.path(forResource: lang, ofType: "lproj"), let bundle = Bundle(path: path) {
        return bundle
    }
    let locale = Locale(identifier: lang)
    if let lan = locale.languageCode {
        lang = lan
        if let script = locale.scriptCode {
            if let path = Bundle.module.path(forResource:  "\(lang)-\(script)", ofType: "lproj"), let bundle = Bundle(path: path) {
                return bundle
            }
        }
        if let path = Bundle.module.path(forResource:  lang, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle
        }
    }
    return nil
}

extension UILabel: LocalizeXib {
    @IBInspectable var setKey: String? {
        get {
            return nil
        }
        set(key) {
            guard let bundle = languageBundle() else {
                return
            }
            
            text = NSLocalizedString(key ?? "key not found", tableName: "Localizable", bundle: bundle, comment: "there is no network")
        }
    }
}

extension UIButton: LocalizeXib {
    @IBInspectable var setKey: String? {
        get {
            return nil
        }
        set(key) {
            guard let bundle = languageBundle() else {
                return
            }
            
            let txt = (NSLocalizedString(key ?? "key not found", tableName: "Localizable", bundle: bundle, comment: "there is no network"))
            setTitle(txt, for: .normal)
        }
    }
}
