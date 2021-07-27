// Copyright © 2021 Geotab Inc. All rights reserved.

import UIKit

protocol ViewPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)

    var presentedViewController: UIViewController? { get }
    var presentingViewController: UIViewController? { get }
}
