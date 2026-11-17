import UIKit

/// Asks the system to open a URL and reports whether it accepted the request.
typealias URLOpener = (_ url: URL, _ completion: @escaping (Bool) -> Void) -> Void

/// The Settings page of the running app, where its permissions and notifications are managed.
enum AppSettings {

    /// The page, as the system names it.
    static var url: URL? {
        URL(string: UIApplication.openSettingsURLString)
    }

    /// Whether `url` is exactly the link to that page. A host, path, query or fragment makes it something else.
    static func isAppSettingsLink(_ url: URL) -> Bool {
        url.absoluteString == UIApplication.openSettingsURLString
    }

    /// Hands `url` to the system on the main queue.
    static func openInSystem(_ url: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: completion)
        }
    }
}
