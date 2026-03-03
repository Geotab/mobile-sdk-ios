/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.9.0_18983"
}

/// :nodoc:
extension MobileSdkConfig {
    public static func start(logger: any Logging) {
        Logger.shared = logger
    }
}
