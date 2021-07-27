// Copyright © 2021 Geotab Inc. All rights reserved.

import Foundation
import CoreMotion

enum MotionActivityType: Int {
    case Unknown = 0
    case Stationary
    case Walking
    case Running
    case Biking
    case Driving
}

class MotionModule: Module {
    let mam = CMMotionActivityManager()
    let webDriveDelegate: WebDriveDelegate
    private var started = false
    private var lastReported = -1
    init(webDriveDelegate: WebDriveDelegate) {
        self.webDriveDelegate = webDriveDelegate
        super.init(name: "motion")
        functions.append(StartMonitoringMotionActivityFunction(module: self))
        functions.append(StopMonitoringMotionActivityFunction(module: self))
    }
    
    func start(_ onComplete: @escaping (Result<String, Error>) -> Void) {
        guard !started else {
            return
        }
        let status = CMMotionActivityManager.authorizationStatus()
        guard status != .restricted && status != .denied else {
            onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion tracking permission not authorized")))
            return
        }
        guard CMMotionActivityManager.isActivityAvailable() else {
            onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion Activity Not Available")))
            return
        }
        let now = Date()
        mam.queryActivityStarting(from: now, to: now, to: .main) { activities, error in
            if let code = error?._code {
                switch code {
                case Int(CMErrorMotionActivityNotAuthorized.rawValue):
                    onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion tracking permission not authorized")))
                case Int(CMErrorMotionActivityNotAvailable.rawValue):
                    onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion Activity Not Available")))
                default:
                    onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion Activity Unknown error")))
                }
                return
            }
            self.mam.startActivityUpdates(to: .main) { activity in
                let type = self.determineActivityType(activity)
                self.updateMotion(type)
            }
            self.lastReported = -1
            self.started = true
            onComplete(Result.success("undefined"))
        }
    }
    
    func stop() {
        guard started else {
            return
        }
        started = false
        lastReported = -1
        mam.stopActivityUpdates()
    }
    
    // return type by priority by speed
    func determineActivityType(_ activity: CMMotionActivity?) -> MotionActivityType{
        guard let activity = activity else {
            return .Unknown
        }
        if activity.automotive {
            return .Driving
        }
        if activity.cycling {
            return .Biking
        }
        if activity.running {
            return .Running
        }
        if activity.walking {
            return .Walking
        }
        if activity.stationary {
            return .Stationary
        }
        return .Unknown
    }
    
    func updateMotion(_ type: MotionActivityType) {
        guard type.rawValue != lastReported else {
            return
        }
        lastReported = type.rawValue
        webDriveDelegate.push(moduleEvent: ModuleEvent(event: "geotab.motion", params: "{ detail: \(type.rawValue) }"))
    }
}
