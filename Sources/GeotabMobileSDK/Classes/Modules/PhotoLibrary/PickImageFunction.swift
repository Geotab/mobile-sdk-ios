import Foundation
import UIKit

class PickImageFunction: ModuleFunction {
    private let helper: ImageFunctionHelper
    
    init(module: Module, filesystem: FilesystemAccessing, imageAccessor: ImageAccessing) {
        helper = ImageFunctionHelper(filesystem: filesystem, imageAccessor: imageAccessor)
        super.init(module: module, name: "pickImage")
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, Error>) -> Void) {
        helper.handleJavascriptCall(argument: argument, jsCallback: jsCallback)
    }
}
