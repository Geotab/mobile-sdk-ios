import Foundation

class AppLogEventSource {
    
    // swift-format-ignore: AlwaysUseLowerCamelCase
    enum LogLevel: Int, Codable {
        case info = 0, warn, Error
    }
    
    public struct LogDetail: Codable {
        let message: String
        let level: LogLevel
    }

    private weak var scriptGateway: (any ScriptGateway)?
    
    private let logLimit: Int
    private let interval: TimeInterval

    private var numberOfLogs = 0
    private var lastReset = Date()
    
    // default is no more than 10 logs fired per 30 mins
    init(scriptGateway: (any ScriptGateway)?, logLimit: Int = 10, interval: TimeInterval = 30 * 60) {
        self.scriptGateway = scriptGateway
        self.logLimit = logLimit
        self.interval = interval
        
        initLoggingPassthrough()
    }
    
    func reset() {
        numberOfLogs = 0
        lastReset = Date()
    }

    private func throttle() -> Bool {
        if Date().timeIntervalSinceReferenceDate - lastReset.timeIntervalSinceReferenceDate > interval {
            reset()
        }
        numberOfLogs += 1
        return (numberOfLogs <= logLimit)
    }
    
    private func initLoggingPassthrough() {
        NotificationCenter.default
            .addObserver(forName: .log, object: nil, queue: nil) { [weak self] notification in
                guard let self else {
                    return
                }
                guard let scriptGateway = self.scriptGateway,
                      let userInfo = notification.userInfo,
                      let level = userInfo["level"] as? Logger.Level,
                      let tag = userInfo["tag"] as? String,
                      let message = userInfo["message"] as? String else {
                    return
                }
                
                // Not sending debug logs to big query
                guard level != .debug else {
                    return
                }

                guard self.throttle() else {
                    return
                }
                
                var detailMessage = "[\(tag)] [\(level.rawValue)] \(message)"
                if let error = userInfo["error"] as? (any Error) {
                    detailMessage += " \(error.localizedDescription)"
                }
                
                let eventDetail = MobileEvent(detail: LogDetail(message: detailMessage, level: level.toLogLevel()))

                if let encodedDetailData = try? JSONEncoder().encode(eventDetail) {
                   let encodedDetailString = String(decoding: encodedDetailData, as: UTF8.self)
                    scriptGateway.push(moduleEvent: ModuleEvent(event: "app.log", params: encodedDetailString)) { _ in }
                }
            }
    }

}

// MARK: - Logging notifications

extension Logger.Level {
    func toLogLevel() -> AppLogEventSource.LogLevel {
        switch self {
        case .error:
            return AppLogEventSource.LogLevel.Error
        case .warn:
            return AppLogEventSource.LogLevel.warn
        case .info:
            return AppLogEventSource.LogLevel.info
        case .debug:
            return AppLogEventSource.LogLevel.info
        }
    }
}
