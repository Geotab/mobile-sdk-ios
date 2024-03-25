import Foundation

enum SecureStorageError: Error {
    case dbPathNotFound
    case couldNotCreateTables(String)
    case sqlite(String?)
    case readError
    case cryptoError
}

protocol SecureStorage {
    func getItem(_ key: String, completion: @escaping (Result<String, Error>) -> Void)
    func setItem(_ key: String, _ value: String, completion: @escaping (Result<String, Error>) -> Void)
    func removeItem(_ key: String, completion: @escaping (Result<String, Error>) -> Void)
    func deleteAll(completion: @escaping (Result<Void, Error>) -> Void)
    func getKeys(completion: @escaping (Result<[String], Error>) -> Void)
    func getLength(completion: @escaping (Result<Int, Error>) -> Void)
}

protocol StorageDatabase {
    var isOpen: Bool { get }
    func initialize() throws
    func open(path: String) throws
    func close()
    func getItem(_ key: String) throws -> Data
    func setItem(_ key: String, value: Data) throws
    func removeItem(_ key: String) throws
    func deleteAll() throws
    func getKeys() throws -> [String]
    func getLength() throws -> Int
}

protocol Encrypting {
    func encrypt(_ value: String) throws -> Data
    func decrypt(_ value: Data) throws -> String
}

class SecureStorageRepository: SecureStorage {
    
    static let shared = SecureStorageRepository()

    let storageDatabase: StorageDatabase
    let encypter: Encrypting

    init(storageDatabase: StorageDatabase = SqliteStorageDatabase(),
         encrypter: Encrypting = Encrypter()) {
        self.storageDatabase = storageDatabase
        self.encypter = encrypter
    }

    private func checkDatabase() throws {
        if !storageDatabase.isOpen {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard let documentsUrl = urls.first else { throw SecureStorageError.dbPathNotFound }
            let databaseUrl = documentsUrl.appendingPathComponent("GeotabDrive.sqlite")
            try storageDatabase.open(path: databaseUrl.path)
        }
        try storageDatabase.initialize()
    }
        
    func getItem(_ key: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try checkDatabase()
            let encryptedValue = try storageDatabase.getItem(key)
            let value = try encypter.decrypt(encryptedValue)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func setItem(_ key: String, _ value: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try checkDatabase()
            let encryptedValue = try encypter.encrypt(value)
            try storageDatabase.setItem(key, value: encryptedValue)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func removeItem(_ key: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try checkDatabase()
            try storageDatabase.removeItem(key)
            completion(.success(key))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteAll(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try checkDatabase()
            try storageDatabase.deleteAll()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getKeys(completion: @escaping (Result<[String], Error>) -> Void) {
        do {
            try checkDatabase()
            let keys = try storageDatabase.getKeys()
            completion(.success(keys))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getLength(completion: @escaping (Result<Int, Error>) -> Void) {
        do {
            try checkDatabase()
            let length = try storageDatabase.getLength()
            completion(.success(length))
        } catch {
            completion(.failure(error))
        }
    }
}
