/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.8.1_18243"
}

/// :nodoc:
extension MobileSdkConfig {
    public static func start(logger: any Logging) {
        Logger.shared = logger
    }
}
