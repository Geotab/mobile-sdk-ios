public import Foundation
import os.log

/// :nodoc:
public protocol Logging {
    func log(level: Logger.Level, tag: String, message: String)
    func event(level: Logger.Level, tag: String, message: String, error: (any Error)?)
}

/// :nodoc:
public enum Logger {
    
    public static internal(set) var shared: any Logging = DefaultLogger()
    
    public enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
    }
}

/// :nodoc:
extension Notification.Name {
    public static let log = Notification.Name("GeotabMobileSDKLog")
}

/// :nodoc:
class DefaultLogger: Logging {
    
    private let osLogger = os.Logger(subsystem: "com.geotab.mobile.sdk", category: "GeotabMobileSDK")
    
    private func toOSLogger(level: Logger.Level, tag: String, message: String, error: (any Error)?) {
        let logMessage = error != nil ? "\(message) \(error!.localizedDescription)" : message
        
        switch level {
        case .debug:
            osLogger.debug("[\(tag, privacy: .public)] \(logMessage, privacy: .public)")
        case .info:
            osLogger.info("[\(tag, privacy: .public)] \(logMessage, privacy: .public)")
        case .warn:
            osLogger.warning("[\(tag, privacy: .public)] \(logMessage, privacy: .public)")
        case .error:
            osLogger.error("[\(tag, privacy: .public)] \(logMessage, privacy: .public)")
        }
    }
    
    private func toNotificationCenter(level: Logger.Level, tag: String, message: String, error: (any Error)?) {
        var userInfo: [String: Any] = [
            "level": level,
            "tag": tag,
            "message": message
        ]
        if let error {
            userInfo["error"] = error
        }
        NotificationCenter.default.post(Notification(name: .log, object: nil, userInfo: userInfo))
    }

    func log(level: Logger.Level, tag: String, message: String) {
        toNotificationCenter(level: level, tag: tag, message: message, error: nil)
        #if DEBUG
        toOSLogger(level: level, tag: tag, message: message, error: nil)
        #endif
    }
    
    func event(level: Logger.Level, tag: String, message: String, error: (any Error)?) {
        toNotificationCenter(level: level, tag: tag, message: message, error: error)
        #if DEBUG
        toOSLogger(level: level, tag: tag, message: message, error: error)
        #endif
    }
}

/// :nodoc:
@propertyWrapper
struct TaggedLogger {
    
    private let tag: String
    
    init(_ tag: String) {
        self.tag = tag
    }

    var wrappedValue: any Logging { Logger.shared }
    var projectedValue: TaggedLogger { self }
    
    func debug(_ message: String) {
        #if DEBUG
        Logger.shared.log(level: .debug, tag: tag, message: message)
        #endif
    }

    func info(_ message: String) {
        Logger.shared.log(level: .info, tag: tag, message: message)
    }

    func warn(_ message: String, error: (any Error)? = nil) {
        Logger.shared.event(level: .warn, tag: tag, message: message, error: error)
    }

    func error(_ message: String, error: (any Error)? = nil) {
        Logger.shared.event(level: .error, tag: tag, message: message, error: error)
    }
}
