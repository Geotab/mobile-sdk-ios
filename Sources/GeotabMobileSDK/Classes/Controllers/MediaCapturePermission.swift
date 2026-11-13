import AVFoundation
import WebKit
import os.log

enum MediaAuthorization {
    case granted, denied, undetermined
}

protocol MediaPermissionProviding {
    var recordPermission: MediaAuthorization { get }
    var cameraPermission: MediaAuthorization { get }
    func requestRecordPermission(_ completion: @escaping (Bool) -> Void)
    func requestCameraPermission(_ completion: @escaping (Bool) -> Void)
}

struct SystemMediaPermissionProvider: MediaPermissionProviding {
    var recordPermission: MediaAuthorization {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return .granted
            case .undetermined: return .undetermined
            default: return .denied
            }
        }
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .granted
        case .undetermined: return .undetermined
        default: return .denied
        }
    }

    var cameraPermission: MediaAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .granted
        case .notDetermined: return .undetermined
        default: return .denied
        }
    }

    func requestRecordPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: completion)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(completion)
        }
    }

    func requestCameraPermission(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }
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
                os_log(.info, log: Self.log, "Microphone %{public}@: %{public}@; host=%{public}@",
                       decision == .deny ? "deny" : "prompt", reason, topLevelHost)
            }
            completion?(decision)
        }
    }

    static func onMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread { action() } else { DispatchQueue.main.async(execute: action) }
    }
}
