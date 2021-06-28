//
//  GeolocationModule.swift
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-08-10.
//

import Foundation
import CoreLocation


class GeolocationModule: Module {
    
    static let PERMISSION_DENIED = "PERMISSION_DENIED"
    static let POSITION_UNAVAILABLE = "POSITION_UNAVAILABLE"
    
    let webDriveDelegate: WebDriveDelegate
    let locationManager: CLLocationManager
    
    var lastLocationResult = GeolocationResult(position: nil, error: nil)
    var isLocationServiceAuthorized = true // default to authorized
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
    
    func requestAuthorization() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
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
        
        // note: startService could be called by different times, if one of the calls requested high accuracy, set it.
        if enableHighAccuracy {
            locationManager.distanceFilter = 0.01
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        
        
        guard !started else {
            return
        }
        
        // make sure everytime user calls startService, we send a request for authorization
        requestAuthorization()
        
//        // note: we are assuming permission granted by default, user may get a denied result event in a later time or timeout if user ignores the authorization request.
//        guard isLocationServiceAuthorized else {
//            updateLastLocation(result: GeolocationResult(position: nil, error: GeolocationModule.PERMISSION_DENIED))
//            throw GeotabDriveErrors.GeolocationError(error: GeolocationModule.PERMISSION_DENIED)
//        }
//
//        locationManager.stopUpdatingLocation()
//        locationManager.startUpdatingLocation()
        
        started = true
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
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            isLocationServiceAuthorized = true
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        } else if status == .denied {
            isLocationServiceAuthorized = false
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
