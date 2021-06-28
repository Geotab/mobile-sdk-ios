import Foundation

protocol AsyncMainExecuterAdapter {
    func after(_ seconds: TimeInterval, execute: @escaping () -> Void)
    
    func run(execute: @escaping () -> Void)
}
