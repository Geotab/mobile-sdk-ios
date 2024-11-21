/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.6.3_15354"
}

/// :nodoc:
public extension MobileSdkConfig {
    static func start(logger: Logging) {
        Logger.shared = logger
    }
}
