/**
 Interface for searching module and module functions.
 */
protocol ModuleContainer: AnyObject {
    func findModule(module: String) -> Module?
    func findModuleFunction(module: String, function: String) -> ModuleFunction?
}
