/**
 Configuration options for  MyGeotabViewController
 */
public class MyGeotabSdkConfig: MobileSdkConfig {
    /**
     The server address to launch MyGeotab from. May include a path component (e.g. "host.server.com/path").
     */
    public static var serverAddress: String = "my.geotab.com"

    /**
     The server host without any path component. Use this for API calls, feature flags, and Sentry configuration.
     */
    public static var serverHost: String {
        if let slashIndex = serverAddress.firstIndex(of: "/") {
            return String(serverAddress[..<slashIndex])
        }
        return serverAddress
    }
}
