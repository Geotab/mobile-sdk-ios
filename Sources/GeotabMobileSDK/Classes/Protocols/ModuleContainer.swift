/**
 Interface for searching module and module functions.
 */
protocol ModuleContainer {
    func findModule(module: String) -> Module?
    func findModuleFunction(module: String, function: String) -> ModuleFunction?
}
