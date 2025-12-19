public import Foundation
import os.log

/// :nodoc:
public protocol Logging {
    func log(level: Logger.Level, tag: String, message: String)
    func log(level: Logger.Level, tag: String, message: String, error: (any Error)?)
    func event(level: Logger.Level, tag: String, message: String, error: (any Error)?, tags: [String: String]?, context: [String: Any]?)
    func event(level: Logger.Level, tag: String, message: String, error: (any Error)?)
    func event(level: Logger.Level, tag: String, message: String)
}

/// :nodoc:
extension Logging {
    func log(level: Logger.Level, tag: String, message: String) {
        log(level: level, tag: tag, message: message, error: nil)
    }

    public func event(level: Logger.Level, tag: String, message: String, error: (any Error)?) {
        event(level: level, tag: tag, message: message, error: error, tags: nil, context: nil)
    }

    public func event(level: Logger.Level, tag: String, message: String) {
        event(level: level, tag: tag, message: message, error: nil, tags: nil, context: nil)
    }
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

    private func formatTags(_ tags: [String: String]) -> String {
        tags.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    }

    private func formatContext(_ context: [String: Any]) -> String {
        context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    }

    private func toOSLogger(level: Logger.Level, tag: String, message: String, error: (any Error)?, tags: [String: String]?, context: [String: Any]?) {
        var logMessage = error != nil ? "\(message) \(error!.localizedDescription)" : message

        if let tags = tags, !tags.isEmpty {
            logMessage += " [tags: \(formatTags(tags))]"
        }
        if let context = context, !context.isEmpty {
            logMessage += " [context: \(formatContext(context))]"
        }

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

    private func toNotificationCenter(level: Logger.Level, tag: String, message: String, error: (any Error)?, tags: [String: String]?, context: [String: Any]?) {
        var userInfo: [String: Any] = [
            "level": level,
            "tag": tag,
            "message": message
        ]
        if let error {
            userInfo["error"] = error
        }
        if let tags {
            userInfo["tags"] = tags
        }
        if let context {
            userInfo["context"] = context
        }
        NotificationCenter.default.post(Notification(name: .log, object: nil, userInfo: userInfo))
    }

    func log(level: Logger.Level, tag: String, message: String, error: (any Error)?) {
        toNotificationCenter(level: level, tag: tag, message: message, error: error, tags: nil, context: nil)
        #if DEBUG
        toOSLogger(level: level, tag: tag, message: message, error: error, tags: nil, context: nil)
        #endif
    }

    func event(level: Logger.Level, tag: String, message: String, error: (any Error)?, tags: [String: String]? = nil, context: [String: Any]? = nil) {
        toNotificationCenter(level: level, tag: tag, message: message, error: error, tags: tags, context: context)
        #if DEBUG
        toOSLogger(level: level, tag: tag, message: message, error: error, tags: tags, context: context)
        #endif
    }
}

/// :nodoc:
@propertyWrapper
public struct TaggedLogger {
    
    private let tag: String
    
    public init(_ tag: String) {
        self.tag = tag
    }

    public var wrappedValue: any Logging { Logger.shared }
    public var projectedValue: TaggedLogger { self }
    
    public func debug(_ message: String) {
        #if DEBUG
        Logger.shared.log(level: .debug, tag: tag, message: message)
        #endif
    }

    public func info(_ message: String) {
        Logger.shared.log(level: .info, tag: tag, message: message)
    }

    public func warn(_ message: String, error: (any Error)? = nil) {
        Logger.shared.log(level: .warn, tag: tag, message: message, error: error)
    }

    public func error(_ message: String, error: (any Error)? = nil) {
        Logger.shared.log(level: .error, tag: tag, message: message, error: error)
    }
}
