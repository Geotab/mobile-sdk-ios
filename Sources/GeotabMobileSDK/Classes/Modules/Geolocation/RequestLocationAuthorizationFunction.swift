import Foundation

protocol LocationServiceAuthorizing: Module {
    func isNotDetermined() -> Bool
    func isAuthorizedWhenInUse() -> Bool
    func requestAuthorizationAlways()
    func requestAuthorizationWhenInUse()
}
