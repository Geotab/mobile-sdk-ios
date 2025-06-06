import Foundation
import UIKit

class PickImageFunction: ModuleFunction {
    private static let functionName: String = "pickImage"
    private let helper: ImageFunctionHelper
    
    init(module: Module, filesystem: FilesystemAccessing, imageAccessor: ImageAccessing) {
        helper = ImageFunctionHelper(filesystem: filesystem, imageAccessor: imageAccessor)
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        helper.handleJavascriptCall(argument: argument, jsCallback: jsCallback)
    }
}
