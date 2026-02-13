import Foundation
import SQLite3

/**
 * WeeklyLogDatabase - Manages persistence for weekly log entries and category colors.
 * 
 * **Bug Fix Note:**
 * Switched from 'SELECT *' to explicit column selection to ensure index stability
 * after migrations (e.g., when adding 'win_note').
 */
class WeeklyLogDatabase {
    
    // MARK: - Singleton
    
    static let shared = WeeklyLogDatabase()
    
    // MARK: - Properties
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.stride.weeklylog", qos: .utility)
    
    /// Consistent column list for all SELECT queries to ensure rowToEntry indices match
    private let entryColumns = "id, date, category, task, time_spent, progress_note, win_note, is_win_of_day, created_at"
    
    private let dbPath: String = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls.first!.appendingPathComponent("Stride")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("weeklylog.db").path
    }()
    
    // MARK: - Initialization
    
    private init() {
        openDatabase()
        if db != nil {
            createTables()
            if getAllEntries().isEmpty {
                insertSampleData()
            }
        }
    }
    
    deinit {
        if db != nil { sqlite3_close(db) }
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening weekly log database")
            db = nil
        }
    }
    
    private func createTables() {
        let createEntriesTable = """
            CREATE TABLE IF NOT EXISTS weekly_log_entries (
                id TEXT PRIMARY KEY,
                date REAL NOT NULL,
                category TEXT NOT NULL,
                task TEXT NOT NULL,
                time_spent REAL NOT NULL,
                progress_note TEXT NOT NULL DEFAULT '',
                win_note TEXT NOT NULL DEFAULT '',
                is_win_of_day INTEGER NOT NULL DEFAULT 0,
                created_at REAL NOT NULL
            );
        """
        
        let createCategoryColorsTable = """
            CREATE TABLE IF NOT EXISTS weekly_log_category_colors (
                category_name TEXT PRIMARY KEY,
                color TEXT NOT NULL
            );
        """
        
        executeSQL(createEntriesTable)
        executeSQL(createCategoryColorsTable)
        migrateWinNoteIfNeeded()
        
        let createDateIndex = "CREATE INDEX IF NOT EXISTS idx_entries_date ON weekly_log_entries(date);"
        executeSQL(createDateIndex)
    }

    private func migrateWinNoteIfNeeded() {
        let checkColumnSQL = "PRAGMA table_info(weekly_log_entries);"
        var statement: OpaquePointer?
        var hasWinNoteColumn = false
        
        if sqlite3_prepare_v2(db, checkColumnSQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let columnName = sqlite3_column_text(statement, 1) {
                    if String(cString: columnName) == "win_note" { hasWinNoteColumn = true }
                }
            }
        }
        sqlite3_finalize(statement)
        
        if !hasWinNoteColumn {
            executeSQL("ALTER TABLE weekly_log_entries ADD COLUMN win_note TEXT NOT NULL DEFAULT '';")
        }
    }
    
    private func executeSQL(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let error = errorMessage {
                print("SQL Error: \(String(cString: error))")
                sqlite3_free(error)
            }
        }
    }
    
    // MARK: - Entry CRUD (Public & Thread-Safe)
    
    func createEntry(_ entry: WeeklyLogEntry) {
        dbQueue.sync {
            guard let db = self.db else { return }
            let sql = "INSERT INTO weekly_log_entries (id, date, category, task, time_spent, progress_note, win_note, is_win_of_day, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
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
            }
            sqlite3_finalize(statement)
            self.unsafeEnsureCategoryColorExists(for: entry.category)
        }
    }
    
    func updateEntry(_ entry: WeeklyLogEntry) {
        dbQueue.sync {
            guard let db = self.db else { return }
            let sql = "UPDATE weekly_log_entries SET date = ?, category = ?, task = ?, time_spent = ?, progress_note = ?, win_note = ?, is_win_of_day = ? WHERE id = ?;"
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, entry.date.timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, (entry.category as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (entry.task as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 4, entry.timeSpent)
                sqlite3_bind_text(statement, 5, (entry.progressNote as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 6, (entry.winNote as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 7, entry.isWinOfDay ? 1 : 0)
                sqlite3_bind_text(statement, 8, (entry.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
            self.unsafeEnsureCategoryColorExists(for: entry.category)
        }
    }
    
    func deleteEntry(id entryId: UUID) {
        dbQueue.sync {
            guard let db = self.db else { return }
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, "DELETE FROM weekly_log_entries WHERE id = ?;", -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (entryId.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getAllEntries() -> [WeeklyLogEntry] {
        return dbQueue.sync {
            guard let db = db else { return [] }
            var entries: [WeeklyLogEntry] = []
            var statement: OpaquePointer?
            let sql = "SELECT \(entryColumns) FROM weekly_log_entries ORDER BY date DESC;"
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let entry = rowToEntry(statement) { entries.append(entry) }
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
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, start)
                sqlite3_bind_double(statement, 2, end)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let entry = rowToEntry(statement) { entries.append(entry) }
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
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, start)
                sqlite3_bind_double(statement, 2, end)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let entry = rowToEntry(statement) { entries.append(entry) }
                }
            }
            sqlite3_finalize(statement)
            return entries
        }
    }
    
    // MARK: - Category Colors (Public & Thread-Safe)
    
    func getCategoryColor(for categoryName: String) -> String? {
        return dbQueue.sync { unsafeGetCategoryColor(for: categoryName) }
    }
    
    func setCategoryColor(for categoryName: String, color: String) {
        dbQueue.sync { self.unsafeSetCategoryColor(for: categoryName, color: color) }
    }
    
    func getAllCategories() -> [String] {
        return dbQueue.sync {
            guard let db = db else { return [] }
            var categories: Set<String> = []
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, "SELECT DISTINCT category FROM weekly_log_entries ORDER BY category;", -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let cString = sqlite3_column_text(statement, 0) { categories.insert(String(cString: cString)) }
                }
            }
            sqlite3_finalize(statement)
            return Array(categories)
        }
    }

    func getCategoryTotals(for weekStartDate: Date) -> [(category: String, total: Double)] {
        let start = weekStartDate.timeIntervalSince1970
        let end = (Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate).timeIntervalSince1970
        let sql = "SELECT category, SUM(time_spent) as total FROM weekly_log_entries WHERE date >= ? AND date < ? GROUP BY category ORDER BY total DESC;"
        
        return dbQueue.sync {
            guard let db = db else { return [] }
            var totals: [(category: String, total: Double)] = []
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, start)
                sqlite3_bind_double(statement, 2, end)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let cString = sqlite3_column_text(statement, 0) {
                        totals.append((category: String(cString: cString), total: sqlite3_column_double(statement, 1)))
                    }
                }
            }
            sqlite3_finalize(statement)
            return totals
        }
    }
    
    // MARK: - Private "Unsafe" Methods
    
    private func unsafeGetCategoryColor(for categoryName: String) -> String? {
        guard let db = db else { return nil }
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT color FROM weekly_log_category_colors WHERE category_name = ?;", -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (categoryName as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    let color = String(cString: cString)
                    sqlite3_finalize(statement)
                    return color
                }
            }
        }
        sqlite3_finalize(statement)
        return nil
    }
    
    private func unsafeSetCategoryColor(for categoryName: String, color: String) {
        guard let db = db else { return }
        let sql = "INSERT INTO weekly_log_category_colors (category_name, color) VALUES (?, ?) ON CONFLICT(category_name) DO UPDATE SET color = excluded.color;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (categoryName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (color as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    private func unsafeEnsureCategoryColorExists(for categoryName: String) {
        if unsafeGetCategoryColor(for: categoryName) == nil {
            let colors = ["#C75B39", "#4A7C59", "#7A6B8A", "#5B7C8C", "#B8834C", "#5A8C8C", "#7A8C8C", "#9C8B7C", "#6B5B6B", "#7C6B5B", "#8C7C6B", "#C4B49C", "#9C7C7C", "#6B7B7B", "#D4A853"]
            unsafeSetCategoryColor(for: categoryName, color: colors.randomElement() ?? "#4A7C59")
        }
    }
    
    private func rowToEntry(_ statement: OpaquePointer?) -> WeeklyLogEntry? {
        guard let statement = statement,
              let idCString = sqlite3_column_text(statement, 0),
              let categoryCString = sqlite3_column_text(statement, 2),
              let taskCString = sqlite3_column_text(statement, 3),
              let progressNotesCString = sqlite3_column_text(statement, 5),
              let winNoteCString = sqlite3_column_text(statement, 6) else { return nil }
        
        return WeeklyLogEntry(
            id: UUID(uuidString: String(cString: idCString)) ?? UUID(),
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
                createEntry(WeeklyLogEntry(date: date, category: sample.category, task: sample.task, timeSpent: sample.time, progressNote: sample.note, isWinOfDay: sample.isWin))
            }
        }
    }
}
