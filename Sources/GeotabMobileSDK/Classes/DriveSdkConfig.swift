/**
 Configuration options for DriveViewController
 */
public class DriveSdkConfig: MobileSdkConfig {
    /// :nodoc:
    public static var apiCallTimeoutSeconds: Double = 9
    
    /**
     The server address to launch Geotab Drive from.
     */
    public static var serverAddress: String = "my.geotab.com"
    
    /// :nodoc:
    public static var backgroundAudioKeepAliveMode: BackgroundAudioKeepAliveMode = .whenNecessary
}

/// :nodoc:
public enum BackgroundAudioKeepAliveMode {
    case never, always, whenNecessary
}
