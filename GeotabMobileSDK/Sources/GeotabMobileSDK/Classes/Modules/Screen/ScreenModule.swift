//
//  ScreenModule.swift
//  GeotabDriveSDK
//
//  Created by Chet Chhom on 2019-12-03.
//

class ScreenModule: Module {
    init() {
        super.init(name: "screen")
        functions.append(KeepAwakeFunction(module: self))
    }
    
}
