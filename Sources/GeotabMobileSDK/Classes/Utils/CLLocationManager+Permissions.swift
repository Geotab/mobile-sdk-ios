import CoreLocation

extension CLLocationManager {
    
    func locationServicesEnabled() -> Bool {
        // Using restricted authorization status instead CLLocationManager().locationServicesEnabled(). The
        // later is slow to run on the UI thread, Apple's suggestion is to use authorization status instead
        getAuthorizationStatus() != .restricted
    }
    
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return authorizationStatus
    }
    
    static func isAuthorizedForAlways() -> Bool {
        CLLocationManager().getAuthorizationStatus() == .authorizedAlways
    }
}
