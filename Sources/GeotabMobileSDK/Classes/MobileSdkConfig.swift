/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.9.4_19371"
}

/// :nodoc:
extension MobileSdkConfig {
    public static func start(logger: any Logging) {
        Logger.shared = logger
    }
}
