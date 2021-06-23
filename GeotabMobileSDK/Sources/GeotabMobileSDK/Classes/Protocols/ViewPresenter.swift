//
//  ViewPresenter.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-04-08.
//
import UIKit

protocol ViewPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)

    var presentedViewController: UIViewController? { get }
    var presentingViewController: UIViewController? { get }
}
