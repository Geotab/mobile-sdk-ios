/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "7.1.23_77994"
}

/// :nodoc:
extension MobileSdkConfig {
    public static func start(logger: any Logging) {
        Logger.shared = logger
    }
}
