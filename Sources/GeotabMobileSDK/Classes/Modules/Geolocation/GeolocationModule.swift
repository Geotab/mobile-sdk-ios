

import Foundation
import CoreLocation


class GeolocationModule: Module {
    
    static let PERMISSION_DENIED = "PERMISSION_DENIED"
    static let POSITION_UNAVAILABLE = "POSITION_UNAVAILABLE"
    
    let webDriveDelegate: WebDriveDelegate
    let locationManager: CLLocationManager
    
    var lastLocationResult = GeolocationResult(position: nil, error: nil)
    var started = false
    
    
    private var requestedHighAccuracy = false
    
    private let defaultDistanceFilter: CLLocationDistance
    private let defaultAccuracy: CLLocationAccuracy
    
    
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        locationManager = CLLocationManager()
        defaultDistanceFilter = locationManager.distanceFilter
        defaultAccuracy = locationManager.desiredAccuracy
        super.init(name: "geolocation")
        functions.append(StartLocationServiceFunction(module: self))
        functions.append(StopLocationServiceFunction(module: self))
        functions.append(RequestLocationAuthorizationFunction(module: self))
        locationManager.delegate = self
//        requestAuthorization()
    }
    
    var isLocationServicesEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    
    override func scripts() -> String {
        var scripts = super.scripts()
        
        let extraTemplate = try! Module.templateRepo.template(named: "Module.Geolocation.Script")
        let scriptData: [String: Any] = ["geotabModules": Module.geotabModules, "moduleName": name, "geotabNativeCallbacks": Module.geotabNativeCallbacks, "callbackPrefix": Module.callbackPrefix]
        scripts += (try? extraTemplate.render(scriptData)) ?? ""
        
        if let data = try? JSONEncoder().encode(lastLocationResult), let json = String(data: data, encoding: .utf8) {
            scripts += """
            window.\(Module.geotabModules).\(name).result = \(json);
            """
        } else {
            scripts += """
            window.\(Module.geotabModules).\(name).result = {};
            """
        }
        
        return scripts
    }
    
    func requestAuthorizationAlways() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
    }
    
    func requestAuthorizationWhenInUse() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func updateLastLocation(result: GeolocationResult) {

        lastLocationResult = result
        guard let data = try? JSONEncoder().encode(result) else {
            return
        }
        
        guard let json = String(data: data, encoding: .utf8) else {
            return
        }
        
        let script = "window.\(Module.geotabModules).\(name).result = \(json);"
        webDriveDelegate.evaluate(script: script) { _ in }
        webDriveDelegate.push(moduleEvent: ModuleEvent(event: "geolocation.result", params: "{ detail: \(json) }"))
    }
    
    func startService(enableHighAccuracy: Bool) throws {
        
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
            accuChanged = locationManager.distanceFilter != 0.01 || locationManager.desiredAccuracy != kCLLocationAccuracyBest
            locationManager.distanceFilter = 0.01
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        
        
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
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
            started = true
        } else if isAuthorizedWhenInUse() {
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
            started = true
            requestAuthorizationAlways()
        } else {
            requestAuthorizationWhenInUse()
            started = true
        }
    }
    
    func isNotDetermined() -> Bool {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus == .notDetermined;
        } else {
            return CLLocationManager.authorizationStatus() == .notDetermined;
        }
    }
    
    func isDeniedOrRestricted() -> Bool {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted;
        } else {
            return CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted;
        }
    }
    
    func isAuthorizedWhenInUse() -> Bool {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus == .authorizedWhenInUse;
        } else {
            return CLLocationManager.authorizationStatus() == .authorizedWhenInUse;
        }
    }
    
    func isAuthorizedAlways() -> Bool {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus == .authorizedAlways
        } else {
            return CLLocationManager.authorizationStatus() == .authorizedAlways
        }
    }
    
    func stopService() {
        guard started else {
            return
        }
        locationManager.stopUpdatingLocation()
        locationManager.distanceFilter = defaultDistanceFilter
        locationManager.desiredAccuracy = defaultAccuracy
        started = false
    }
    
    deinit {
        // make sure to stop when DriveViewController is destroyed.
        stopService()
    }
    
    
}

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
    
}
