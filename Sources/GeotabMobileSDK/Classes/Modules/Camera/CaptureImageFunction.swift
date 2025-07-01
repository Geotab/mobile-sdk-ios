class CaptureImageFunction: ModuleFunction {
    private static let functionName: String = "captureImage"
    private let helper: ImageFunctionHelper
    
    init(module: Module, filesystem: any FilesystemAccessing, imageAccessor: any ImageAccessing) {
        helper = ImageFunctionHelper(filesystem: filesystem, imageAccessor: imageAccessor)
        super.init(module: module, name: Self.functionName)
    }
    
    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        helper.handleJavascriptCall(argument: argument, jsCallback: jsCallback)
    }
}
