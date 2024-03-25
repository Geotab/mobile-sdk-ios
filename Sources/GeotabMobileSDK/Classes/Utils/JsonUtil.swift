import Foundation

enum JsonContants {
    static let success = "\"success\""
    static let emptyArray = "[]"
    static let zero = "0"
}

func toJson<T: Encodable>(_ val: T) -> String? {
    guard let data = try? JSONEncoder().encode(val) else {
        return nil
    }
    return String(data: data, encoding: .utf8)
}

// A common pattern used to ensure valid JSON is passed as a function arugument
func jsonArgumentToData(_ argument: Any?) -> Data? {
    guard let argument,
          JSONSerialization.isValidJSONObject(argument) else {
        return nil
    }
    return try? JSONSerialization.data(withJSONObject: argument)
}

func jsonArgumentToString(_ argument: Any?) -> String? {
    guard let argument,
          let stringArg = argument as? String else {
        return nil
    }
    return stringArg
}

// MARK: - JsonArgumentDecoding

// Enables simulated throws in unit tests for JSON decoding
protocol JsonArgumentDecoding {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

class JsonArgumentDecoder: JsonArgumentDecoding {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - JSON encoded details for push events

struct MobileEvent<T: Codable>: Codable {
    let detail: T
}
