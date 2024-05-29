import Foundation
import CommonCrypto

class Encrypter: Encrypting {
    static let account = "GeotabMobileSDK"
    static let service = "LocaleStorage"
    
    func encrypt(_ value: String) throws -> Data {
        let key = try getOrCreateKey()
        guard let data = value.data(using: .utf8) else { throw SecureStorageError.cryptoError }
        return try cryptCC(data: data, key: key, operation: kCCEncrypt)
    }
    
    func decrypt(_ value: Data) throws -> String {
        guard let key = try getKey() else { throw SecureStorageError.cryptoError }
        let data = try cryptCC(data: value, key: key, operation: kCCDecrypt)
        return String(decoding: data, as: UTF8.self)
    }
    
    private func generateSymmetricEncryptionKey() throws -> Data {
        var keyData = Data(count: kCCKeySizeAES128)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, kCCKeySizeAES128, $0.baseAddress!)
        }
        guard result == errSecSuccess else { throw SecureStorageError.cryptoError }
        return keyData
    }
    
    func getOrCreateKey() throws -> Data {
        if let key = try getKey(),
           key.count == kCCKeySizeAES128 {
            return key
        }
        
        let key = try generateSymmetricEncryptionKey()
        try save(keyData: key)
        return key
    }
    
    func getKey() throws -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: Self.account,
                                    kSecAttrService as String: Self.service,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess,
              let existingItem = item as? [String: Any],
              let key = existingItem[kSecValueData as String] as? Data else {
            throw SecureStorageError.cryptoError
        }
        return key
    }
    
    private func save(keyData: Data) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: Self.account,
                                    kSecAttrService as String: Self.service,
                                    kSecValueData as String: keyData]
        var status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let attributes: [String: Any] = [kSecValueData as String: keyData]
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
        
        guard status == errSecSuccess else { throw SecureStorageError.cryptoError }
    }

    private func cryptCC(data: Data, key: Data, operation: Int) throws -> Data {

        guard key.count == kCCKeySizeAES128 else { throw SecureStorageError.cryptoError }

        var ivBytes: [UInt8]
        var inBytes: [UInt8]
        var outLength: Int

        if operation == kCCEncrypt {
            ivBytes = [UInt8](repeating: 0, count: kCCBlockSizeAES128)
            guard kCCSuccess == SecRandomCopyBytes(kSecRandomDefault, ivBytes.count, &ivBytes) else {
                throw SecureStorageError.cryptoError
            }

            inBytes = Array(data)
            outLength = data.count + kCCBlockSizeAES128

        } else {
            ivBytes = Array(Array(data).dropLast(data.count - kCCBlockSizeAES128))
            inBytes = Array(Array(data).dropFirst(kCCBlockSizeAES128))
            outLength = inBytes.count

        }

        var outBytes = [UInt8](repeating: 0, count: outLength)
        var bytesMutated = 0

        guard kCCSuccess == CCCrypt(CCOperation(operation),
                                    CCAlgorithm(kCCAlgorithmAES128),
                                    CCOptions(kCCOptionPKCS7Padding), 
                                    [UInt8](key),
                                    key.count,
                                    &ivBytes,
                                    &inBytes,
                                    inBytes.count,
                                    &outBytes,
                                    outLength,
                                    &bytesMutated) else {
            throw SecureStorageError.cryptoError
        }

        var outData = Data(bytes: &outBytes, count: bytesMutated)

        if operation == kCCEncrypt {
            ivBytes.append(contentsOf: Array(outData))
            outData = Data(ivBytes)
        }
        
        return outData
    }
}
