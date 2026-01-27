import UIKit

extension UIApplication {

    var window: UIWindow? {
        let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.first
        return (scene as? UIWindowScene)?.windows.first
    }

    var rootViewController : UIViewController {
        if let rootViewController =  UIApplication.shared.window?.rootViewController?.topMostViewController {
            return rootViewController
        } else  {
            return UIViewController()
        }
    }

    /// Waits for a view controller with a valid window to be available.
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds (default: 0.5s)
    ///   - pollInterval: Time between checks in nanoseconds (default: 250ms)
    @MainActor
    func waitForValidPresenter(timeout: TimeInterval = 0.5, pollInterval: UInt64 = 250_000_000) async throws -> UIViewController {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            try? await Task.sleep(nanoseconds: pollInterval)
            let presenter = rootViewController
            if presenter.view.window != nil {
                return presenter
            }
        }
        throw AuthError.noExternalUserAgent
    }
}

extension UIViewController {

    var topMostViewController: UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topMostViewController
        } else if let navigationController = self as? UINavigationController {
            return navigationController.topViewController?.topMostViewController ?? self
        } else if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController ?? self
        } else {
            return self
        }
    }
}
