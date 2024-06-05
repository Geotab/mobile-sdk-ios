import Foundation
import CommonCrypto

class Encrypter: Encrypting {
    static let account = "GeotabMobileSDK"
    static let service = "LocaleStorage"
    
    func encrypt(_ value: String) throws -> Data {
        let key = try getOrCreateKey()
        guard let data = value.data(using: .utf8) else { throw SecureStorageError.cryptoError }
        return try Self.crypt(data: data, key: key, operation: kCCEncrypt)
    }
    
    func decrypt(_ value: Data) throws -> String {
        guard let key = try getKey() else { throw SecureStorageError.cryptoError }
        let data = try Self.crypt(data: value, key: key, operation: kCCDecrypt)
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

    // The initialization vector for encryption is prefixed to the encrypted value in
    // the returned Data object
    private static func crypt(data: Data, key: Data, operation: Int) throws -> Data {
        
        var dataToCrypt = data
        
        var ivBytes: [UInt8]
        if operation == kCCEncrypt {
            ivBytes = [UInt8](repeating: 0, count: kCCBlockSizeAES128)
            guard kCCSuccess == SecRandomCopyBytes(kSecRandomDefault, ivBytes.count, &ivBytes) else {
                throw SecureStorageError.cryptoError
            }
        } else {
            ivBytes = Array(Array(data).dropLast(data.count - kCCBlockSizeAES128))
            dataToCrypt = data.subdata(in: kCCBlockSizeAES128..<data.count)
        }
        let iv = Data(bytes: ivBytes, count: ivBytes.count)
        
        var cryptorRef: CCCryptorRef?
        var status = withUnsafePointers(iv, key, { ivBytes, keyBytes in
            return CCCryptorCreateWithMode(
                CCOperation(operation),
                CCMode(kCCModeCTR),
                CCAlgorithm(kCCAlgorithmAES128),
                CCPadding(kCCOptionPKCS7Padding),
                ivBytes,
                keyBytes, key.count,
                nil, 0, 0,
                CCModeOptions(),
                &cryptorRef)
        })
        guard status == noErr, 
                let cryptor = cryptorRef else { throw SecureStorageError.cryptoError }

        defer { _ = CCCryptorRelease(cryptor) }

        let needed = CCCryptorGetOutputLength(cryptor, data.count, true)
        var result = Data(count: needed)
        let rescount = result.count
        var updateLen: size_t = 0
        status = withUnsafePointers(dataToCrypt, &result, { dataBytes, resultBytes in
            return CCCryptorUpdate(
                cryptor,
                dataBytes, dataToCrypt.count,
                resultBytes, rescount,
                &updateLen)
        })
        guard status == noErr else { throw SecureStorageError.cryptoError }

        var finalLen: size_t = 0
        status = result.withUnsafeMutableBytes { resultBytes -> OSStatus in
            return CCCryptorFinal(
                cryptor,
                resultBytes.baseAddress! + updateLen,
                rescount - updateLen,
                &finalLen)
        }
        guard status == noErr else { throw SecureStorageError.cryptoError }

        result.count = updateLen + finalLen
        
        if operation == kCCEncrypt {
            result = iv + result
        }

        return result
    }
}
    
private func withUnsafePointers<A0, A1, Result>(_ arg0: Data,
                                                _ arg1: Data,
                                                _ body: (UnsafePointer<A0>, UnsafePointer<A1>) throws -> Result) rethrows -> Result {
    return try arg0.withUnsafeBytes { p0 -> Result in
        return try arg1.withUnsafeBytes { p1 -> Result in
            return try body(p0.bindMemory(to: A0.self).baseAddress!,
                            p1.bindMemory(to: A1.self).baseAddress!)
        }
    }
}

private func withUnsafePointers<A0, A1, Result>(_ arg0: Data,
                                                _ arg1: inout Data,
                                                _ body: (UnsafePointer<A0>, UnsafeMutablePointer<A1>) throws -> Result) rethrows -> Result {
    return try arg0.withUnsafeBytes { p0 -> Result in
        return try arg1.withUnsafeMutableBytes { p1 -> Result in
            return try body(p0.bindMemory(to: A0.self).baseAddress!,
                            p1.bindMemory(to: A1.self).baseAddress!)
        }
    }
}
