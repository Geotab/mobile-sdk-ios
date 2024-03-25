import Foundation
import CoreLocation
import UIKit

protocol LocationManager {
    var distanceFilter: CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var showsBackgroundLocationIndicator: Bool { get set }
    
    func requestAlwaysAuthorization()
    func requestWhenInUseAuthorization()
    
    func startUpdatingLocation()
    func stopUpdatingLocation()
    
    func getAuthorizationStatus() -> CLAuthorizationStatus
    func setDelegate(_ delegate: CLLocationManagerDelegate)
    func locationServicesEnabled() -> Bool
}

/// :nodoc:
class GeolocationModule: Module {
    static let moduleName = "geolocation"
    static let PERMISSION_DENIED = "PERMISSION_DENIED"
    static let POSITION_UNAVAILABLE = "POSITION_UNAVAILABLE"
    
    let scriptGateway: ScriptGateway
    var locationManager: LocationManager
    let isInBackground: () -> Bool
    
    var lastLocationResult = GeolocationResult(position: nil, error: nil)
    var started = false
    var stopLocationUpdatesWhenForegrounded = false
    
    private var requestedHighAccuracy = false
    
    private let defaultAccuracy: CLLocationAccuracy
    
    let options: MobileSdkOptions
    
    init(scriptGateway: ScriptGateway,
         options: MobileSdkOptions,
         locationbManager: LocationManager = CLLocationManager(),
         isInBackground: @escaping (() -> Bool) = { UIApplication.shared.applicationState != .active }) {
        self.scriptGateway = scriptGateway
        self.options = options
        self.locationManager = locationbManager
        self.isInBackground = isInBackground
        defaultAccuracy = locationManager.desiredAccuracy
        super.init(name: GeolocationModule.moduleName)
        functions.append(StartLocationServiceFunction(starter: self))
        functions.append(StopLocationServiceFunction(stopper: self))
        locationManager.setDelegate(self)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(backgroundModeChanged),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    var isLocationServicesEnabled: Bool {
        locationManager.locationServicesEnabled()
    }
    
    override func scripts() -> String {
        var scripts = super.scripts()
        
        let extraTemplate = try! Module.templateRepo.template(named: "Module.Geolocation.Script")
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": name, "geotabNativeCallbacks": Module.geotabNativeCallbacks, "callbackPrefix": Module.callbackPrefix]
        scripts += (try? extraTemplate.render(scriptData)) ?? ""
        
        if let data = try? JSONEncoder().encode(lastLocationResult), let json = String(data: data, encoding: .utf8) {
            scripts +=
                """
                    if (window.\(Module.geotabModules) != null && window.\(Module.geotabModules).\(name) != null) {
                        window.\(Module.geotabModules).\(name).result = \(json);
                    }
                """
        } else {
            scripts +=
                """
                    if (window.\(Module.geotabModules) != null && window.\(Module.geotabModules).\(name) != null) {
                        window.\(Module.geotabModules).\(name).result = {};
                    }
                """
        }
        
        return scripts
    }
    
    func updateLastLocation(result: GeolocationResult) {

        lastLocationResult = result
        guard let data = try? JSONEncoder().encode(result) else {
            return
        }
        
        guard let json = String(data: data, encoding: .utf8) else {
            return
        }
        
        evaluateScript(json: json)
        scriptGateway.push(moduleEvent: ModuleEvent(event: "geolocation.result", params: "{ \"detail\": \(json) }")) { _ in }
    }
    
    deinit {
        // make sure to stop when DriveViewController is destroyed.
        stopService()
    }
}

// MARK: - LocationServiceAuthorizing
/// :nodoc:
extension GeolocationModule: LocationServiceAuthorizing {
    
    func isNotDetermined() -> Bool {
        return locationManager.getAuthorizationStatus() == .notDetermined
    }
    
    func isDeniedOrRestricted() -> Bool {
        let authorizationStatus = locationManager.getAuthorizationStatus()
        return (authorizationStatus == .denied || authorizationStatus == .restricted)
    }
    
    func isAuthorizedWhenInUse() -> Bool {
        return locationManager.getAuthorizationStatus() == .authorizedWhenInUse
    }
    
    func isAuthorizedAlways() -> Bool {
        return locationManager.getAuthorizationStatus() == .authorizedAlways
    }
    
    func requestAuthorizationAlways() {
        if options.shouldPromptForPermissions {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func requestAuthorizationWhenInUse() {
        if options.shouldPromptForPermissions {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

// MARK: - LocationServiceStopping
/// :nodoc:
extension GeolocationModule: LocationServiceStopping {
    
    func stopService() {
        guard started else {
            return
        }
        
        guard !isInBackground() else {
            stopLocationUpdatesWhenForegrounded = true
            return
        }
        
        locationManager.stopUpdatingLocation()
        locationManager.desiredAccuracy = defaultAccuracy
        started = false
    }
}

// MARK: - LocationServiceStarting
/// :nodoc:
extension GeolocationModule: LocationServiceStarting {
    
    func startService(enableHighAccuracy: Bool) throws {
        
        if stopLocationUpdatesWhenForegrounded {
            stopLocationUpdatesWhenForegrounded = false
        }
        
        requestedHighAccuracy = enableHighAccuracy
        guard isLocationServicesEnabled else {
            updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.POSITION_UNAVAILABLE))
            throw GeotabDriveErrors.GeolocationError(error: GeolocationModule.POSITION_UNAVAILABLE)
        }
        
        if isDeniedOrRestricted() {
            updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.PERMISSION_DENIED))
            throw GeotabDriveErrors.GeolocationError(error: GeolocationModule.PERMISSION_DENIED)
        }
        
        // note: startService could be called by different times, if one of the calls requested high accuracy, set it.
        var accuChanged = false
        if enableHighAccuracy {
            accuChanged = (locationManager.desiredAccuracy != kCLLocationAccuracyBest)
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }

        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        guard !started else {
            if isNotDetermined() {
                requestAuthorizationWhenInUse()
            } else if accuChanged && isAuthorizedAlways() {
                locationManager.stopUpdatingLocation()
                locationManager.startUpdatingLocation()
            } else if isAuthorizedWhenInUse() {
                requestAuthorizationAlways()
                if accuChanged {
                    locationManager.stopUpdatingLocation()
                    locationManager.startUpdatingLocation()
                }
            }
            return
        }
        
        if isAuthorizedAlways() {
            locationManager.startUpdatingLocation()
            started = true
        } else if isAuthorizedWhenInUse() {
            locationManager.startUpdatingLocation()
            started = true
            requestAuthorizationAlways()
        } else {
            requestAuthorizationWhenInUse()
            started = true
        }
    }
}

// MARK: - CLLocationManagerDelegate
/// :nodoc:
extension GeolocationModule: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if started {
                locationManager.stopUpdatingLocation()
                locationManager.startUpdatingLocation()
            }
        } else if status == .authorizedWhenInUse {
            if started {
                requestAuthorizationAlways()
                locationManager.stopUpdatingLocation()
                locationManager.startUpdatingLocation()
            }
        } else if status == .denied {
            updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.PERMISSION_DENIED))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let err = error as? CLError {
            switch err {
            case CLError.locationUnknown:
                updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.POSITION_UNAVAILABLE))
            case CLError.denied:
                updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.PERMISSION_DENIED))
            default:
                updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.POSITION_UNAVAILABLE))
            }
        } else {
            updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.POSITION_UNAVAILABLE))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            return
        }
        
        let coords = GeolocationCoordinates(latitude: lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude, altitude: lastLocation.altitude, accuracy: lastLocation.horizontalAccuracy, altitudeAccuracy: lastLocation.verticalAccuracy, heading: lastLocation.course, speed: lastLocation.speed)
        
        let pos = GeolocationPosition(coords: coords, timestamp: UInt64(Date().timeIntervalSince1970 * 1000))
        
        let result = GeolocationResult(position: pos, error: nil)
        updateLastLocation(result: result)
    }
    
    func evaluateScript(json: String) {
        let script =
            """
                if (window.\(Module.geotabModules) != null && window.\(Module.geotabModules).\(name) != null) {
                    window.\(Module.geotabModules).\(name).result = \(json);
                }
            """
        scriptGateway.evaluate(script: script) { _ in }
    }
    
}

// MARK: - Background status changes
/// :nodoc:
extension GeolocationModule {
    @objc
    func backgroundModeChanged(notification: NSNotification) {
        if stopLocationUpdatesWhenForegrounded {
            stopLocationUpdatesWhenForegrounded = false
            stopService()
        }
    }
}

// MARK: - CLLocationManager adapter

extension CLLocationManager: LocationManager {
    func setDelegate(_ delegate: CLLocationManagerDelegate) {
        self.delegate = delegate
    }
}
