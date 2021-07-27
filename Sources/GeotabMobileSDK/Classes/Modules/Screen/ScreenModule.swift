// Copyright © 2021 Geotab Inc. All rights reserved.

class ScreenModule: Module {
    init() {
        super.init(name: "screen")
        functions.append(KeepAwakeFunction(module: self))
    }
    
}
