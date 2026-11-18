import WebKit
import os.log

public enum MediaAuthorization: Sendable, Equatable {
    case granted, denied, undetermined
}

// All handler access is serialized on main, including teardown and late OS callbacks.
final class MediaDecisionOnce {
    private var handler: ((WKPermissionDecision) -> Void)?
    private let topLevelHost: String?
    private static let log = OSLog(subsystem: "com.geotab.mobileSDK", category: "UIDelegate")

    init(topLevelHost: String? = nil, _ handler: @escaping (WKPermissionDecision) -> Void) {
        self.topLevelHost = topLevelHost
        self.handler = handler
    }

    func resolve(_ decision: WKPermissionDecision, reason: String = "delegate released") {
        Self.onMain { [self] in
            let completion = handler
            handler = nil
            if completion != nil, decision != .grant, let topLevelHost {
                os_log(.info, log: Self.log, "Media capture %{public}@: %{public}@; host=%{public}@",
                       decision == .deny ? "deny" : "prompt", reason, topLevelHost)
            }
            completion?(decision)
        }
    }

    static func onMain(_ action: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { action() }
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
