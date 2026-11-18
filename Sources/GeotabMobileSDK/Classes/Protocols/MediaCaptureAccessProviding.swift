import Foundation

/// Implement only in apps that declare NSMicrophoneUsageDescription and, for combined
/// capture, NSCameraUsageDescription. Camera-only capture uses WebKit's prompt.
/// The SDK calls all members on the main thread; implementations must be safe to
/// call there. Authorization may be read while inactive, but access is requested
/// only while the app is active. The completion may be called on any queue.
/// Main-actor-isolated types can conform by marking these members `nonisolated`.
public protocol MediaCaptureAccessProviding: Sendable {
    var microphoneAuthorization: MediaAuthorization { get }
    func requestMicrophoneAccess(_ completion: @escaping @Sendable (Bool) -> Void)
    var cameraAuthorization: MediaAuthorization { get }
    func requestCameraAccess(_ completion: @escaping @Sendable (Bool) -> Void)
}
