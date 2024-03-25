class ScreenModule: Module {
    static let moduleName = "screen"

    init() {
        super.init(name: ScreenModule.moduleName)
        functions.append(KeepAwakeFunction(module: self))
    }
    
}
