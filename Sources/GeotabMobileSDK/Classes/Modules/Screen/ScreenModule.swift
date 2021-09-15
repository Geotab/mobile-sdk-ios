

class ScreenModule: Module {
    init() {
        super.init(name: "screen")
        functions.append(KeepAwakeFunction(module: self))
    }
    
}
