import Foundation
import SQLite3
import os.log

// MARK: - Database Error Types

enum DatabaseError: Error, LocalizedError {
    case connectionFailed(path: String)
    case queryFailed(sql: String, message: String)
    case executeFailed(sql: String, message: String)
    case migrationFailed(version: Int, message: String)
    case bindingFailed(parameter: Int)
    case rowExtractionFailed
    case databaseNotInitialized
    case invalidUUID(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let path):
            return "Failed to open database at: \(path)"
        case .queryFailed(let sql, let message):
            return "Query failed: \(message)\nSQL: \(sql.prefix(100))"
        case .executeFailed(let sql, let message):
            return "Execute failed: \(message)\nSQL: \(sql.prefix(100))"
        case .migrationFailed(let version, let message):
            return "Migration to version \(version) failed: \(message)"
        case .bindingFailed(let parameter):
            return "Failed to bind parameter at position \(parameter)"
        case .rowExtractionFailed:
            return "Failed to extract row data"
        case .databaseNotInitialized:
            return "Database connection not initialized"
        case .invalidUUID(let string):
            return "Invalid UUID string: \(string)"
        }
    }
}

// MARK: - Database Logger

enum DatabaseLogger {
    private static let subsystem = "com.stride.database"
    
    static let general = Logger(subsystem: subsystem, category: "general")
    static let migration = Logger(subsystem: subsystem, category: "migration")
    static let query = Logger(subsystem: subsystem, category: "query")
    static let error = Logger(subsystem: subsystem, category: "error")
    
    static func logOpen(path: String, success: Bool) {
        if success {
            general.info("Opened database: \(path)")
        } else {
            error.error("Failed to open database: \(path)")
        }
    }
    
    static func logExecute(sql: String, success: Bool, errorMessage: String? = nil) {
        let truncatedSQL = String(sql.prefix(100))
        if success {
            query.debug("Executed: \(truncatedSQL)")
        } else {
            error.error("Execute failed: \(errorMessage ?? "unknown") - SQL: \(truncatedSQL)")
        }
    }
    
    static func logMigration(from: Int, to: Int, success: Bool) {
        if success {
            migration.info("Migrated database from version \(from) to \(to)")
        } else {
            migration.error("Migration from \(from) to \(to) failed")
        }
    }
    
    static func logClose(path: String) {
        general.info("Closed database: \(path)")
    }
}

// MARK: - Migration Protocol

protocol DatabaseMigration {
    var version: Int { get }
    var description: String { get }
    func execute(on db: OpaquePointer) throws
}

// MARK: - Base Database Class

class BaseDatabase {
    
    var db: OpaquePointer?
    let dbQueue: DispatchQueue
    let dbPath: String
    let filename: String
    
    var currentVersion: Int {
        dbQueue.sync {
            guard let db = db else { return 0 }
            var statement: OpaquePointer?
            var version = 0
            
            if sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    version = Int(sqlite3_column_int(statement, 0))
                }
            }
            sqlite3_finalize(statement)
            return version
        }
    }
    
    init(filename: String, queueLabel: String) {
        self.filename = filename
        self.dbPath = Self.buildDBPath(filename: filename)
        self.dbQueue = DispatchQueue(label: queueLabel, qos: .utility)
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Path
    
    static func buildDBPath(filename: String) -> String {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls.first!.appendingPathComponent("Stride")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent(filename).path
    }
    
    // MARK: - Connection Management
    
    func openDatabase() -> Result<Void, DatabaseError> {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let error = DatabaseError.connectionFailed(path: dbPath)
            DatabaseLogger.logOpen(path: dbPath, success: false)
            return .failure(error)
        }
        DatabaseLogger.logOpen(path: dbPath, success: true)
        return .success(())
    }
    
    func closeDatabase() {
        guard let db = db else { return }
        sqlite3_close(db)
        self.db = nil
        DatabaseLogger.logClose(path: dbPath)
    }
    
    // MARK: - SQL Execution
    
    func execute(_ sql: String) -> Result<Void, DatabaseError> {
        guard let db = db else {
            return .failure(.databaseNotInitialized)
        }
        
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        
        if result != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            DatabaseLogger.logExecute(sql: sql, success: false, errorMessage: message)
            return .failure(.executeFailed(sql: sql, message: message))
        }
        
        DatabaseLogger.logExecute(sql: sql, success: true)
        return .success(())
    }
    
    func executeUnsafe(_ sql: String) {
        guard let db = db else { return }
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let error = errorMessage {
                DatabaseLogger.logExecute(sql: sql, success: false, errorMessage: String(cString: error))
                sqlite3_free(error)
            }
        }
    }
    
    // MARK: - Migration System
    
    func runMigrations(_ migrations: [DatabaseMigration]) -> Result<Void, DatabaseError> {
        let current = currentVersion
        let pending = migrations.filter { $0.version > current }.sorted { $0.version < $1.version }
        
        guard !pending.isEmpty else {
            DatabaseLogger.migration.info("No pending migrations (current version: \(current))")
            return .success(())
        }
        
        DatabaseLogger.migration.info("Running \(pending.count) migration(s) from version \(current)")
        
        for migration in pending {
            do {
                try migration.execute(on: db!)
                setUserVersion(migration.version)
                DatabaseLogger.logMigration(from: current, to: migration.version, success: true)
            } catch {
                DatabaseLogger.logMigration(from: current, to: migration.version, success: false)
                return .failure(.migrationFailed(version: migration.version, message: error.localizedDescription))
            }
        }
        
        return .success(())
    }
    
    private func setUserVersion(_ version: Int) {
        executeUnsafe("PRAGMA user_version = \(version);")
    }
    
    // MARK: - Prepared Statement Helpers
    
    func prepareStatement(_ sql: String) -> Result<OpaquePointer, DatabaseError> {
        guard let db = db else {
            return .failure(.databaseNotInitialized)
        }
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        
        guard result == SQLITE_OK, let stmt = statement else {
            return .failure(.queryFailed(sql: sql, message: "Failed to prepare statement"))
        }
        
        return .success(stmt)
    }
    
    func bindText(_ statement: OpaquePointer, position: Int32, _ value: String) -> Result<Void, DatabaseError> {
        let result = sqlite3_bind_text(statement, position, (value as NSString).utf8String, -1, nil)
        guard result == SQLITE_OK else {
            return .failure(.bindingFailed(parameter: Int(position)))
        }
        return .success(())
    }
    
    func bindDouble(_ statement: OpaquePointer, position: Int32, _ value: Double) -> Result<Void, DatabaseError> {
        let result = sqlite3_bind_double(statement, position, value)
        guard result == SQLITE_OK else {
            return .failure(.bindingFailed(parameter: Int(position)))
        }
        return .success(())
    }
    
    func bindInt(_ statement: OpaquePointer, position: Int32, _ value: Int32) -> Result<Void, DatabaseError> {
        let result = sqlite3_bind_int(statement, position, value)
        guard result == SQLITE_OK else {
            return .failure(.bindingFailed(parameter: Int(position)))
        }
        return .success(())
    }
    
    func bindUUID(_ statement: OpaquePointer, position: Int32, _ uuid: UUID) -> Result<Void, DatabaseError> {
        return bindText(statement, position: position, uuid.uuidString)
    }
    
    func bindOptionalDouble(_ statement: OpaquePointer, position: Int32, _ value: Double?) -> Result<Void, DatabaseError> {
        if let value = value {
            return bindDouble(statement, position: position, value)
        } else {
            let result = sqlite3_bind_null(statement, position)
            guard result == SQLITE_OK else {
                return .failure(.bindingFailed(parameter: Int(position)))
            }
            return .success(())
        }
    }
    
    func columnText(_ statement: OpaquePointer, column: Int32) -> String? {
        guard let text = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: text)
    }
    
    func columnUUID(_ statement: OpaquePointer, column: Int32) -> UUID? {
        guard let text = columnText(statement, column: column) else { return nil }
        return UUID(uuidString: text)
    }
    
    func columnDouble(_ statement: OpaquePointer, column: Int32) -> Double {
        return sqlite3_column_double(statement, column)
    }
    
    func columnDate(_ statement: OpaquePointer, column: Int32) -> Date {
        return Date(timeIntervalSince1970: sqlite3_column_double(statement, column))
    }
    
    func columnInt(_ statement: OpaquePointer, column: Int32) -> Int32 {
        return sqlite3_column_int(statement, column)
    }
    
    func columnBool(_ statement: OpaquePointer, column: Int32) -> Bool {
        return sqlite3_column_int(statement, column) == 1
    }
    
    func isColumnNull(_ statement: OpaquePointer, column: Int32) -> Bool {
        return sqlite3_column_type(statement, column) == SQLITE_NULL
    }
    
    func step(_ statement: OpaquePointer) -> Bool {
        return sqlite3_step(statement) == SQLITE_ROW
    }
    
    func finalize(_ statement: OpaquePointer) {
        sqlite3_finalize(statement)
    }
    
    // MARK: - Transaction Support
    
    func beginTransaction() -> Result<Void, DatabaseError> {
        return execute("BEGIN TRANSACTION;")
    }
    
    func commit() -> Result<Void, DatabaseError> {
        return execute("COMMIT;")
    }
    
    func rollback() -> Result<Void, DatabaseError> {
        return execute("ROLLBACK;")
    }
    
    func withTransaction<T>(_ block: () throws -> T) -> Result<T, DatabaseError> {
        switch beginTransaction() {
        case .success:
            do {
                let result = try block()
                switch commit() {
                case .success:
                    return .success(result)
                case .failure(let error):
                    return .failure(error)
                }
            } catch {
                _ = rollback()
                if let dbError = error as? DatabaseError {
                    return .failure(dbError)
                }
                return .failure(.executeFailed(sql: "transaction", message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
