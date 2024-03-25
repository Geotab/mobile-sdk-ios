import Foundation
import CoreMotion

protocol MotionActivityAdapter: AnyObject {
    func getAuthStatus() -> CMAuthorizationStatus
    func getAvailability() -> Bool
    func callStopActivityUpdates()
    func callStartActivityUpdates(to queue: OperationQueue, withHandler handler: @escaping CMMotionActivityHandler)
    func callQueryActivityStarting(from start: Date, to end: Date, to queue: OperationQueue, withHandler handler: @escaping CMMotionActivityQueryHandler)
}

extension CMMotionActivityManager: MotionActivityAdapter {
    func callQueryActivityStarting(from start: Date, to end: Date, to queue: OperationQueue, withHandler handler: @escaping CMMotionActivityQueryHandler) {
        queryActivityStarting(from: start, to: end, to: queue, withHandler: handler)
    }
    
    func callStartActivityUpdates(to queue: OperationQueue, withHandler handler: @escaping CMMotionActivityHandler) {
        startActivityUpdates(to: queue, withHandler: handler)
    }
    
    func getAuthStatus() -> CMAuthorizationStatus {
        return CMMotionActivityManager.authorizationStatus()
    }

    func getAvailability() -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    func callStopActivityUpdates() {
        stopActivityUpdates()
    }
    
}

enum MotionActivityType: Int {
    case Unknown = 0
    case Stationary
    case Walking
    case Running
    case Biking
    case Driving
}

class MotionModule: Module {
    static let moduleName = "motion"

    let motionAdapter: MotionActivityAdapter
    let scriptGateway: ScriptGateway
    let options: MobileSdkOptions
    private var started = false
    private var lastReported = -1
    init(scriptGateway: ScriptGateway, options: MobileSdkOptions, adapter: MotionActivityAdapter = CMMotionActivityManager()) {
        self.motionAdapter = adapter
        self.options = options
        self.scriptGateway = scriptGateway
        super.init(name: MotionModule.moduleName)
        functions.append(StartMonitoringMotionActivityFunction(module: self))
        functions.append(StopMonitoringMotionActivityFunction(module: self))
    }
    
    func start(_ onComplete: @escaping (Result<String, Error>) -> Void) {
        onComplete(Result.success("undefined"))
/*        guard options.shouldPromptForPermissions else {
            onComplete(Result.success("undefined"))
            return
        }

        guard !started else {
            onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion already started")))
            return
        }
        let status = motionAdapter.getAuthStatus()
        guard status != .restricted && status != .denied else {
            onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion tracking permission not authorized")))
            return
        }
        guard motionAdapter.getAvailability() else {
            onComplete(Result.failure(GeotabDriveErrors.MotionActivityError(error: "Motion Activity Not Available")))
            return
        }
        let now = Date()
        motionAdapter.callQueryActivityStarting(from: now, to: now, to: .main) { _, error in
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
            self.motionAdapter.callStartActivityUpdates(to: .main) { activity in
                let type = self.determineActivityType(activity)
                self.updateMotion(type)
            }
            self.lastReported = -1
            self.started = true
            onComplete(Result.success("undefined"))
        }*/
    }
    
    func stop() {
        guard started else {
            return
        }
        started = false
        lastReported = -1
        motionAdapter.callStopActivityUpdates()
    }
    
    // return type by priority by speed
    func determineActivityType(_ activity: CMMotionActivity?) -> MotionActivityType {
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
        scriptGateway.push(moduleEvent: ModuleEvent(event: "geotab.motion", params: "{ \"detail\": \(type.rawValue) }")) { _ in } 
    }
}
