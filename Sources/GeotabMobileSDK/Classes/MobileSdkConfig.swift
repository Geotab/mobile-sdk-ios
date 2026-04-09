/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.9.1_19213"
}

/// :nodoc:
extension MobileSdkConfig {
    public static func start(logger: any Logging) {
        Logger.shared = logger
    }
}
