import Foundation

protocol JsonSerializableError: Error {
    var asJson: String? { get }
}
