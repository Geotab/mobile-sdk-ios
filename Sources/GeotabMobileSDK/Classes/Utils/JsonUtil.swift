

import Foundation

func toJson<T: Encodable>(_ val: T) -> String? {
    guard let data = try? JSONEncoder().encode(val) else {
        return nil
    }
    return String(data: data, encoding: .utf8)
}
