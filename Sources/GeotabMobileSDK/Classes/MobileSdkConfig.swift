/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.5.1_14540"
}

/// :nodoc:
public extension MobileSdkConfig {
    static func start(logger: Logging) {
        Logger.shared = logger
    }
}
