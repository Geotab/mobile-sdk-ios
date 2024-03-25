import Foundation
import SQLite3

class SqliteStorageDatabase: StorageDatabase {
    
    private var dbPointer: OpaquePointer?
    
    var isOpen: Bool { dbPointer != nil }
    
    private var lastSqliteError: SecureStorageError {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return .sqlite(errorMessage)
        } else {
            return .sqlite(nil)
        }
    }
    
    deinit {
        close()
    }
    
    func close() {
        guard let dbPointer else { return }
        sqlite3_close(dbPointer)
        self.dbPointer = nil
    }
    
    func open(path: String) throws {
        close()
        guard sqlite3_open(path, &dbPointer) == SQLITE_OK else {
            close()
            throw lastSqliteError
        }
    }
    
    private func prepareStatement(_ sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastSqliteError
        }
        return statement
    }
    
    private func bindTextParamToStatement(_ statement: OpaquePointer?, index: Int32, text: String) throws {
        let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
        guard sqlite3_bind_text(statement, index, text, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
            throw lastSqliteError
        }
    }

    private func bindBlobParamToStatement(_ statement: OpaquePointer?, index: Int32, blob: Data) throws {
        let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
        guard sqlite3_bind_blob(statement, index, [UInt8](blob), Int32(blob.count), SQLITE_TRANSIENT) == SQLITE_OK else {
            throw lastSqliteError
        }
    }

    func initialize() throws {
        let createTableQuery = "CREATE TABLE IF NOT EXISTS SecureStorage(Key TEXT PRIMARY KEY NOT NULL, Value BLOB);"
        let createTableStatement = try prepareStatement(createTableQuery)
        defer { sqlite3_finalize(createTableStatement) }
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else { throw lastSqliteError }
    }
    
    func getItem(_ key: String) throws -> Data {
        let getItemQuery = "SELECT * FROM SecureStorage WHERE Key = ?;"
        let queryStatement = try prepareStatement(getItemQuery)
        defer { sqlite3_finalize(queryStatement) }
        try bindTextParamToStatement(queryStatement, index: 1, text: key)
        guard sqlite3_step(queryStatement) == SQLITE_ROW else { throw lastSqliteError }
        guard let dataBlob = sqlite3_column_blob(queryStatement, 1) else { throw SecureStorageError.readError }
        let dataBlobLength = sqlite3_column_bytes(queryStatement, 1)
        let data = Data(bytes: dataBlob, count: Int(dataBlobLength))
        return data
    }
    
    func setItem(_ key: String, value: Data) throws {
        let setItemQuery = "INSERT OR REPLACE INTO SecureStorage (key, value) VALUES (?, ?);"
        let queryStatement = try prepareStatement(setItemQuery)
        defer { sqlite3_finalize(queryStatement) }
        try bindTextParamToStatement(queryStatement, index: 1, text: key)
        try bindBlobParamToStatement(queryStatement, index: 2, blob: value)
        guard sqlite3_step(queryStatement) == SQLITE_DONE else { throw lastSqliteError }
    }
    
    func removeItem(_ key: String) throws {
        let removeItemQuery = "DELETE FROM SecureStorage WHERE Key = ?;"
        let queryStatement = try prepareStatement(removeItemQuery)
        defer { sqlite3_finalize(queryStatement) }
        try bindTextParamToStatement(queryStatement, index: 1, text: key)
        guard sqlite3_step(queryStatement) == SQLITE_DONE else { throw lastSqliteError }
    }
    
    func deleteAll() throws {
        let deleteAllQuery = "DELETE FROM SecureStorage;"
        let queryStatement = try prepareStatement(deleteAllQuery)
        defer { sqlite3_finalize(queryStatement) }
        guard sqlite3_step(queryStatement) == SQLITE_DONE else { throw lastSqliteError }
    }
    
    func getKeys() throws -> [String] {
        let getKeysQuery = "SELECT Key FROM SecureStorage;"
        let queryStatement = try prepareStatement(getKeysQuery)
        defer { sqlite3_finalize(queryStatement) }
        
        var keys = [String]()
        
        while sqlite3_step(queryStatement) == SQLITE_ROW {
            if let key = sqlite3_column_text(queryStatement, 0) {
                keys.append(String(cString: key))
            } else {
                throw SecureStorageError.readError
            }
        }
        
        return keys
    }
    
    func getLength() throws -> Int {
        let getLengthQuery = "SELECT COUNT(*) FROM SecureStorage;"
        let queryStatement = try prepareStatement(getLengthQuery)
        defer { sqlite3_finalize(queryStatement) }
        guard sqlite3_step(queryStatement) == SQLITE_ROW else { throw lastSqliteError }
        return Int(sqlite3_column_int(queryStatement, 0))
    }
}
