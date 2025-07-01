public import Foundation

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

    private func toConsole(level: Logger.Level, tag: String, message: String, error: (any Error)?) {
        if let error = error {
            NSLog("[\(level.rawValue)] [\(tag)] \(message) \(error.localizedDescription)")
        } else {
            NSLog("[\(level.rawValue)] [\(tag)] \(message)")
        }
    }
    
    func log(level: Logger.Level, tag: String, message: String) {
        toConsole(level: level, tag: tag, message: message, error: nil)
        toNotificationCenter(level: level, tag: tag, message: message, error: nil)
    }
    
    func event(level: Logger.Level, tag: String, message: String, error: (any Error)?) {
        toConsole(level: level, tag: tag, message: message, error: error)
        toNotificationCenter(level: level, tag: tag, message: message, error: error)
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
