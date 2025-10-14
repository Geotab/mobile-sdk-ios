/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.7.2_18130"
}

/// :nodoc:
extension MobileSdkConfig {
    public static func start(logger: any Logging) {
        Logger.shared = logger
    }
}
