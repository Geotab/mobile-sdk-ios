import UIKit

extension UIApplication {
    
    var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
            .flatMap { $0 as? UIWindowScene }?
            .windows.first
    }
    
    var rootViewController : UIViewController {
        if let rootViewController =  UIApplication.shared.window?.rootViewController?.topMostViewController {
            return rootViewController
        } else  {
            return UIViewController()
        }
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
