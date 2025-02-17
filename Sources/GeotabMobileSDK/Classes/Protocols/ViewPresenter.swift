import UIKit

protocol ViewPresenter: AnyObject {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)

    var presentedViewController: UIViewController? { get }
    var presentingViewController: UIViewController? { get }
}
