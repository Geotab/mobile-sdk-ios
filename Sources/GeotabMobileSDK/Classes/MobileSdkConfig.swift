/// :nodoc:
public class MobileSdkConfig {
    public static let sdkVersion = "6.6.2_15094"
}

/// :nodoc:
public extension MobileSdkConfig {
    static func start(logger: Logging) {
        Logger.shared = logger
    }
}
