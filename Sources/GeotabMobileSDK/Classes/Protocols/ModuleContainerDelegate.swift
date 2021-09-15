

/**
 Interface for searching module and module functions.
 */
protocol ModuleContainerDelegate {
    func findModule(module: String) -> Module?
    func findModuleFunction(module: String, function: String) -> ModuleFunction?
}
