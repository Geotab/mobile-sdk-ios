import Foundation

extension URL {
    var domain: String? {
        if let components = host?.components(separatedBy: "."),
           components.count > 2 {
            return components.suffix(2).joined(separator: ".")
        }
        return host
    }
}
