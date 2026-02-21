import Foundation
import SQLite3
import os.log

// MARK: - Weekly Log Database Migrations

struct WeeklyLogMigrationV1: DatabaseMigration {
    let version = 1
    let description = "Initial schema with weekly_log_entries and category_colors tables"
    
    func execute(on db: OpaquePointer) throws {
        let createEntriesTable = """
            CREATE TABLE IF NOT EXISTS weekly_log_entries (
                id TEXT PRIMARY KEY,
                date REAL NOT NULL,
                category TEXT NOT NULL,
                task TEXT NOT NULL,
                time_spent REAL NOT NULL,
                progress_note TEXT NOT NULL DEFAULT '',
                created_at REAL NOT NULL
            );
        """
        
        let createCategoryColorsTable = """
            CREATE TABLE IF NOT EXISTS weekly_log_category_colors (
                category_name TEXT PRIMARY KEY,
                color TEXT NOT NULL
            );
        """
        
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(db, createEntriesTable, nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            throw DatabaseError.executeFailed(sql: createEntriesTable, message: msg)
        }
        
        if sqlite3_exec(db, createCategoryColorsTable, nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            throw DatabaseError.executeFailed(sql: createCategoryColorsTable, message: msg)
        }
        
        if sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_entries_date ON weekly_log_entries(date);", nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            throw DatabaseError.executeFailed(sql: "CREATE INDEX", message: msg)
        }
    }
}

struct WeeklyLogMigrationV2: DatabaseMigration {
    let version = 2
    let description = "Add win_note and is_win_of_day columns"
    
    func execute(on db: OpaquePointer) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        let addWinNote = "ALTER TABLE weekly_log_entries ADD COLUMN win_note TEXT NOT NULL DEFAULT '';"
        if sqlite3_exec(db, addWinNote, nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            if !msg.contains("duplicate column") {
                throw DatabaseError.executeFailed(sql: addWinNote, message: msg)
            }
        }
        
        let addIsWinOfDay = "ALTER TABLE weekly_log_entries ADD COLUMN is_win_of_day INTEGER NOT NULL DEFAULT 0;"
        if sqlite3_exec(db, addIsWinOfDay, nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            if !msg.contains("duplicate column") {
                throw DatabaseError.executeFailed(sql: addIsWinOfDay, message: msg)
            }
        }
    }
}

// MARK: - Weekly Log Database Error (Backward Compatibility)

typealias WeeklyLogDatabaseResult<T> = Result<T, DatabaseError>

// MARK: - Weekly Log Database

final class WeeklyLogDatabase: BaseDatabase {
    
    static let shared = WeeklyLogDatabase()
    
    private let entryColumns = "id, date, category, task, time_spent, progress_note, win_note, is_win_of_day, created_at"
    
    private let migrations: [DatabaseMigration] = [
        WeeklyLogMigrationV1(),
        WeeklyLogMigrationV2()
    ]
    
    private let defaultCategoryColors = [
        "#C75B39", "#4A7C59", "#7A6B8A", "#5B7C8C", "#B8834C",
        "#5A8C8C", "#7A8C8C", "#9C8B7C", "#6B5B6B", "#7C6B5B",
        "#8C7C6B", "#C4B49C", "#9C7C7C", "#6B7B7B", "#D4A853"
    ]
    
    private init() {
        super.init(filename: "weeklylog.db", queueLabel: "com.stride.weeklylog")
        
        switch openDatabase() {
        case .success:
            _ = runMigrations(migrations)
            if getAllEntries().isEmpty {
                insertSampleData()
            }
        case .failure(let error):
            DatabaseLogger.error.error("Failed to initialize WeeklyLogDatabase: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Entry CRUD
    
    func createEntry(_ entry: WeeklyLogEntry) -> WeeklyLogDatabaseResult<Void> {
        return dbQueue.sync {
            guard let db = db else { return .failure(.databaseNotInitialized) }
            
            let sql = "INSERT INTO weekly_log_entries (id, date, category, task, time_spent, progress_note, win_note, is_win_of_day, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return .failure(.queryFailed(sql: sql, message: "Prepare failed"))
            }
            
            sqlite3_bind_text(statement, 1, (entry.id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 2, entry.date.timeIntervalSince1970)
            sqlite3_bind_text(statement, 3, (entry.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (entry.task as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 5, entry.timeSpent)
            sqlite3_bind_text(statement, 6, (entry.progressNote as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (entry.winNote as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 8, entry.isWinOfDay ? 1 : 0)
            sqlite3_bind_double(statement, 9, entry.createdAt.timeIntervalSince1970)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
            
            unsafeEnsureCategoryColorExists(for: entry.category)
            return .success(())
        }
    }
    
    func updateEntry(_ entry: WeeklyLogEntry) -> WeeklyLogDatabaseResult<Void> {
        return dbQueue.sync {
            guard let db = db else { return .failure(.databaseNotInitialized) }
            
            let sql = "UPDATE weekly_log_entries SET date = ?, category = ?, task = ?, time_spent = ?, progress_note = ?, win_note = ?, is_win_of_day = ? WHERE id = ?;"
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return .failure(.queryFailed(sql: sql, message: "Prepare failed"))
            }
            
            sqlite3_bind_double(statement, 1, entry.date.timeIntervalSince1970)
            sqlite3_bind_text(statement, 2, (entry.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (entry.task as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 4, entry.timeSpent)
            sqlite3_bind_text(statement, 5, (entry.progressNote as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (entry.winNote as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 7, entry.isWinOfDay ? 1 : 0)
            sqlite3_bind_text(statement, 8, (entry.id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
            
            unsafeEnsureCategoryColorExists(for: entry.category)
            return .success(())
        }
    }
    
    func deleteEntry(id entryId: UUID) -> WeeklyLogDatabaseResult<Void> {
        return dbQueue.sync {
            guard let db = db else { return .failure(.databaseNotInitialized) }
            
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, "DELETE FROM weekly_log_entries WHERE id = ?;", -1, &statement, nil) == SQLITE_OK else {
                return .failure(.queryFailed(sql: "DELETE", message: "Prepare failed"))
            }
            
            sqlite3_bind_text(statement, 1, (entryId.uuidString as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
            
            return .success(())
        }
    }
    
    func getAllEntries() -> [WeeklyLogEntry] {
        return dbQueue.sync {
            guard let db = db else { return [] }
            
            var entries: [WeeklyLogEntry] = []
            var statement: OpaquePointer?
            let sql = "SELECT \(entryColumns) FROM weekly_log_entries ORDER BY date DESC;"
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return entries
            }
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = rowToEntry(statement) {
                    entries.append(entry)
                }
            }
            
            sqlite3_finalize(statement)
            return entries
        }
    }
    
    func getEntriesForWeek(startingFrom weekStartDate: Date) -> [WeeklyLogEntry] {
        let start = weekStartDate.timeIntervalSince1970
        let end = (Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate).timeIntervalSince1970
        
        return dbQueue.sync {
            guard let db = db else { return [] }
            
            var entries: [WeeklyLogEntry] = []
            var statement: OpaquePointer?
            let sql = "SELECT \(entryColumns) FROM weekly_log_entries WHERE date >= ? AND date < ? ORDER BY date ASC;"
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return entries
            }
            
            sqlite3_bind_double(statement, 1, start)
            sqlite3_bind_double(statement, 2, end)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = rowToEntry(statement) {
                    entries.append(entry)
                }
            }
            
            sqlite3_finalize(statement)
            return entries
        }
    }
    
    func getEntriesForDate(_ date: Date) -> [WeeklyLogEntry] {
        let start = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        let end = (Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date).timeIntervalSince1970
        
        return dbQueue.sync {
            guard let db = db else { return [] }
            
            var entries: [WeeklyLogEntry] = []
            var statement: OpaquePointer?
            let sql = "SELECT \(entryColumns) FROM weekly_log_entries WHERE date >= ? AND date < ? ORDER BY date ASC;"
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return entries
            }
            
            sqlite3_bind_double(statement, 1, start)
            sqlite3_bind_double(statement, 2, end)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = rowToEntry(statement) {
                    entries.append(entry)
                }
            }
            
            sqlite3_finalize(statement)
            return entries
        }
    }
    
    // MARK: - Category Colors
    
    func getCategoryColor(for categoryName: String) -> String? {
        return dbQueue.sync { unsafeGetCategoryColor(for: categoryName) }
    }
    
    func setCategoryColor(for categoryName: String, color: String) -> WeeklyLogDatabaseResult<Void> {
        return dbQueue.sync {
            unsafeSetCategoryColor(for: categoryName, color: color)
            return .success(())
        }
    }
    
    func getAllCategories() -> [String] {
        return dbQueue.sync {
            guard let db = db else { return [] }
            
            var categories: Set<String> = []
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, "SELECT DISTINCT category FROM weekly_log_entries ORDER BY category;", -1, &statement, nil) == SQLITE_OK else {
                return Array(categories)
            }
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    categories.insert(String(cString: cString))
                }
            }
            
            sqlite3_finalize(statement)
            return Array(categories)
        }
    }
    
    func getCategoryTotals(for weekStartDate: Date) -> [(category: String, total: Double)] {
        let start = weekStartDate.timeIntervalSince1970
        let end = (Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate).timeIntervalSince1970
        
        return dbQueue.sync {
            guard let db = db else { return [] }
            
            var totals: [(category: String, total: Double)] = []
            var statement: OpaquePointer?
            let sql = "SELECT category, SUM(time_spent) as total FROM weekly_log_entries WHERE date >= ? AND date < ? GROUP BY category ORDER BY total DESC;"
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return totals
            }
            
            sqlite3_bind_double(statement, 1, start)
            sqlite3_bind_double(statement, 2, end)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    totals.append((category: String(cString: cString), total: sqlite3_column_double(statement, 1)))
                }
            }
            
            sqlite3_finalize(statement)
            return totals
        }
    }
    
    // MARK: - Private Helpers
    
    private func unsafeGetCategoryColor(for categoryName: String) -> String? {
        guard let db = db else { return nil }
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT color FROM weekly_log_category_colors WHERE category_name = ?;", -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        sqlite3_bind_text(statement, 1, (categoryName as NSString).utf8String, -1, nil)
        
        var color: String?
        if sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                color = String(cString: cString)
            }
        }
        
        sqlite3_finalize(statement)
        return color
    }
    
    private func unsafeSetCategoryColor(for categoryName: String, color: String) {
        guard let db = db else { return }
        
        let sql = "INSERT INTO weekly_log_category_colors (category_name, color) VALUES (?, ?) ON CONFLICT(category_name) DO UPDATE SET color = excluded.color;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        
        sqlite3_bind_text(statement, 1, (categoryName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (color as NSString).utf8String, -1, nil)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }
    
    private func unsafeEnsureCategoryColorExists(for categoryName: String) {
        if unsafeGetCategoryColor(for: categoryName) == nil {
            let color = defaultCategoryColors.randomElement() ?? "#4A7C59"
            unsafeSetCategoryColor(for: categoryName, color: color)
        }
    }
    
    private func rowToEntry(_ statement: OpaquePointer?) -> WeeklyLogEntry? {
        guard let statement = statement,
              let idCString = sqlite3_column_text(statement, 0),
              let categoryCString = sqlite3_column_text(statement, 2),
              let taskCString = sqlite3_column_text(statement, 3),
              let progressNotesCString = sqlite3_column_text(statement, 5),
              let winNoteCString = sqlite3_column_text(statement, 6) else { return nil }
        
        let id = UUID(uuidString: String(cString: idCString)) ?? UUID()
        
        return WeeklyLogEntry(
            id: id,
            date: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
            category: String(cString: categoryCString),
            task: String(cString: taskCString),
            timeSpent: sqlite3_column_double(statement, 4),
            progressNote: String(cString: progressNotesCString),
            winNote: String(cString: winNoteCString),
            isWinOfDay: sqlite3_column_int(statement, 7) == 1,
            createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 8))
        )
    }
    
    private func insertSampleData() {
        let calendar = Calendar.current
        let lastMonday = Date().startOfWeek
        let samples: [(day: Int, category: String, task: String, time: Double, note: String, isWin: Bool)] = [
            (0, "Reading", "Deep Work", 1.0, "Finished Chapter 3", true),
            (1, "Learning", "Swift concurrency", 1.5, "Completed tutorial", true),
            (5, "Personal", "Built Stride features", 1.5, "Updated Weekly Log", true)
        ]
        
        for sample in samples {
            if let date = calendar.date(byAdding: .day, value: sample.day, to: lastMonday) {
                let entry = WeeklyLogEntry(
                    date: date,
                    category: sample.category,
                    task: sample.task,
                    timeSpent: sample.time,
                    progressNote: sample.note,
                    isWinOfDay: sample.isWin
                )
                _ = createEntry(entry)
            }
        }
    }
}
