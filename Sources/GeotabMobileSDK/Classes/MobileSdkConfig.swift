/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.7.0_15676"
}

/// :nodoc:
public extension MobileSdkConfig {
    static func start(logger: Logging) {
        Logger.shared = logger
    }
}
