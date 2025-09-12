/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.7.2_17967"
}

/// :nodoc:
extension MobileSdkConfig {
    public static func start(logger: any Logging) {
        Logger.shared = logger
    }
}
