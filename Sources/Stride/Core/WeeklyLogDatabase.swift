import Foundation
import SQLite3

/**
 * WeeklyLogDatabase - Manages persistence for weekly log entries and category colors
 *
 * Provides CRUD operations for pomodoro/focus session tracking.
 * Uses raw SQLite3 C API (consistent with existing UsageDatabase).
 */
class WeeklyLogDatabase {
    
    // MARK: - Singleton
    
    static let shared = WeeklyLogDatabase()
    
    // MARK: - Properties
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.stride.weeklylog", qos: .utility)
    
    /// Path to the SQLite database file
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
            // Insert sample data if empty
            if getAllEntries().isEmpty {
                insertSampleData()
            }
        } else {
            print("Failed to initialize weekly log database")
        }
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    // MARK: - Database Setup
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening weekly log database at path: \(dbPath)")
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
        
        // Create index for faster date queries
        let createDateIndex = """
            CREATE INDEX IF NOT EXISTS idx_entries_date ON weekly_log_entries(date);
        """
        executeSQL(createDateIndex)
    }
    
    private func executeSQL(_ sql: String) {
        guard let db = db else { return }
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let error = errorMessage {
                print("SQL Error: \(String(cString: error))")
                sqlite3_free(error)
            }
        }
    }
    
    // MARK: - CRUD Operations - Entries
    
    func createEntry(_ entry: WeeklyLogEntry) {
        guard let db = db else { return }
        
        let sql = """
            INSERT INTO weekly_log_entries (id, date, category, task, time_spent, progress_note, is_win_of_day, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (entry.id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 2, entry.date.timeIntervalSince1970)
            sqlite3_bind_text(statement, 3, (entry.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (entry.task as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 5, entry.timeSpent)
            sqlite3_bind_text(statement, 6, (entry.progressNote as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 7, entry.isWinOfDay ? 1 : 0)
            sqlite3_bind_double(statement, 8, entry.createdAt.timeIntervalSince1970)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Failed to create entry")
            }
            
            sqlite3_finalize(statement)
            
            // Ensure category color exists
            ensureCategoryColorExists(for: entry.category)
        }
    }
    
    func updateEntry(_ entry: WeeklyLogEntry) {
        guard let db = db else { return }
        
        let sql = """
            UPDATE weekly_log_entries
            SET date = ?, category = ?, task = ?, time_spent = ?, progress_note = ?, is_win_of_day = ?
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, entry.date.timeIntervalSince1970)
            sqlite3_bind_text(statement, 2, (entry.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (entry.task as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 4, entry.timeSpent)
            sqlite3_bind_text(statement, 5, (entry.progressNote as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 6, entry.isWinOfDay ? 1 : 0)
            sqlite3_bind_text(statement, 7, (entry.id.uuidString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Failed to update entry")
            }
            
            sqlite3_finalize(statement)
            
            // Ensure category color exists
            ensureCategoryColorExists(for: entry.category)
        }
    }
    
    func deleteEntry(id entryId: UUID) {
        guard let db = db else { return }
        
        let sql = "DELETE FROM weekly_log_entries WHERE id = ?;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (entryId.uuidString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Failed to delete entry")
            }
            
            sqlite3_finalize(statement)
        }
    }
    
    func getAllEntries() -> [WeeklyLogEntry] {
        guard let db = db else { return [] }
        
        var entries: [WeeklyLogEntry] = []
        let sql = "SELECT * FROM weekly_log_entries ORDER BY date DESC;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = rowToEntry(statement) {
                    entries.append(entry)
                }
            }
            sqlite3_finalize(statement)
        }
        
        return entries
    }
    
    func getEntriesForWeek(startingFrom weekStartDate: Date) -> [WeeklyLogEntry] {
        guard let db = db else { return [] }
        
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
        
        let startTimestamp = weekStartDate.timeIntervalSince1970
        let endTimestamp = weekEndDate.timeIntervalSince1970
        
        var entries: [WeeklyLogEntry] = []
        let sql = "SELECT * FROM weekly_log_entries WHERE date >= ? AND date < ? ORDER BY date ASC;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startTimestamp)
            sqlite3_bind_double(statement, 2, endTimestamp)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = rowToEntry(statement) {
                    entries.append(entry)
                }
            }
            sqlite3_finalize(statement)
        }
        
        return entries
    }
    
    func getEntriesForDate(_ date: Date) -> [WeeklyLogEntry] {
        guard let db = db else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let startTimestamp = startOfDay.timeIntervalSince1970
        let endTimestamp = endOfDay.timeIntervalSince1970
        
        var entries: [WeeklyLogEntry] = []
        let sql = "SELECT * FROM weekly_log_entries WHERE date >= ? AND date < ? ORDER BY date ASC;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startTimestamp)
            sqlite3_bind_double(statement, 2, endTimestamp)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let entry = rowToEntry(statement) {
                    entries.append(entry)
                }
            }
            sqlite3_finalize(statement)
        }
        
        return entries
    }
    
    // MARK: - Category Colors
    
    func getCategoryColor(for categoryName: String) -> String? {
        guard let db = db else { return nil }
        
        let sql = "SELECT color FROM weekly_log_category_colors WHERE category_name = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (categoryName as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    let color = String(cString: cString)
                    sqlite3_finalize(statement)
                    return color
                }
            }
            sqlite3_finalize(statement)
        }
        
        return nil
    }
    
    func setCategoryColor(for categoryName: String, color: String) {
        guard let db = db else { return }
        
        let sql = """
            INSERT INTO weekly_log_category_colors (category_name, color)
            VALUES (?, ?)
            ON CONFLICT(category_name) DO UPDATE SET color = excluded.color;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (categoryName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (color as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Failed to set category color")
            }
            
            sqlite3_finalize(statement)
        }
    }
    
    func getAllCategories() -> [String] {
        guard let db = db else { return [] }
        
        var categories: Set<String> = []
        let sql = "SELECT DISTINCT category FROM weekly_log_entries ORDER BY category;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    categories.insert(String(cString: cString))
                }
            }
            sqlite3_finalize(statement)
        }
        
        return Array(categories)
    }
    
    func getAllCategoryColors() -> [CategoryColor] {
        guard let db = db else { return [] }
        
        var colors: [CategoryColor] = []
        let sql = "SELECT * FROM weekly_log_category_colors;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let nameCString = sqlite3_column_text(statement, 0),
                   let colorCString = sqlite3_column_text(statement, 1) {
                    let categoryName = String(cString: nameCString)
                    let color = String(cString: colorCString)
                    colors.append(CategoryColor(categoryName: categoryName, color: color))
                }
            }
            sqlite3_finalize(statement)
        }
        
        return colors
    }
    
    // MARK: - Statistics
    
    func getWeeklyTotal(for weekStartDate: Date) -> Double {
        let entries = getEntriesForWeek(startingFrom: weekStartDate)
        return entries.reduce(0) { $0 + $1.timeSpent }
    }
    
    func getDailyTotals(for weekStartDate: Date) -> [Date: Double] {
        let entries = getEntriesForWeek(startingFrom: weekStartDate)
        let calendar = Calendar.current
        
        var totals: [Date: Double] = [:]
        
        for entry in entries {
            let startOfDay = calendar.startOfDay(for: entry.date)
            totals[startOfDay, default: 0] += entry.timeSpent
        }
        
        return totals
    }
    
    func getCategoryTotals(for weekStartDate: Date) -> [(category: String, total: Double)] {
        guard let db = db else { return [] }
        
        var totals: [(category: String, total: Double)] = []
        
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
        let startTimestamp = weekStartDate.timeIntervalSince1970
        let endTimestamp = weekEndDate.timeIntervalSince1970
        
        let sql = """
            SELECT category, SUM(time_spent) as total
            FROM weekly_log_entries
            WHERE date >= ? AND date < ?
            GROUP BY category
            ORDER BY total DESC;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startTimestamp)
            sqlite3_bind_double(statement, 2, endTimestamp)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    let category = String(cString: cString)
                    let total = sqlite3_column_double(statement, 1)
                    totals.append((category: category, total: total))
                }
            }
            sqlite3_finalize(statement)
        }
        
        return totals
    }
    
    func getWins(for weekStartDate: Date) -> [WeeklyLogEntry] {
        let entries = getEntriesForWeek(startingFrom: weekStartDate)
        return entries.filter { $0.isWinOfDay }
    }
    
    // MARK: - Export
    
    func exportToCSV(startDate: Date, endDate: Date) -> String {
        var csv = "Date,Day,Category,Task,Pomodoros,Minutes,Progress Notes,Win of the Day\n"
        
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            let entries = getEntriesForDate(currentDate)
            
            for entry in entries {
                let dateStr = entry.date.formattedDay
                let dayStr = entry.date.shortDayName
                let pomodoros = String(format: "%.2f", entry.timeSpent)
                let minutes = entry.timeInMinutes
                let winStr = entry.isWinOfDay ? "Yes" : "No"
                
                // Escape commas and quotes in text fields
                let escapedCategory = entry.category.replacingOccurrences(of: "\"", with: "\"\"")
                let escapedTask = entry.task.replacingOccurrences(of: "\"", with: "\"\"")
                let escapedNotes = entry.progressNote.replacingOccurrences(of: "\"", with: "\"\"")
                
                csv += "\"\(dateStr)\",\"\(dayStr)\",\"\(escapedCategory)\",\"\(escapedTask)\",\(pomodoros),\(minutes),\"\(escapedNotes)\",\(winStr)\n"
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return csv
    }
    
    // MARK: - Helper Methods
    
    private func rowToEntry(_ statement: OpaquePointer?) -> WeeklyLogEntry? {
        guard let statement = statement else { return nil }
        
        guard let idCString = sqlite3_column_text(statement, 0),
              let categoryCString = sqlite3_column_text(statement, 2),
              let taskCString = sqlite3_column_text(statement, 3),
              let notesCString = sqlite3_column_text(statement, 5) else {
            return nil
        }
        
        let id = String(cString: idCString)
        let date = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
        let category = String(cString: categoryCString)
        let task = String(cString: taskCString)
        let timeSpent = sqlite3_column_double(statement, 4)
        let progressNote = String(cString: notesCString)
        let isWin = sqlite3_column_int(statement, 6) == 1
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
        
        guard let uuid = UUID(uuidString: id) else { return nil }
        
        return WeeklyLogEntry(
            id: uuid,
            date: date,
            category: category,
            task: task,
            timeSpent: timeSpent,
            progressNote: progressNote,
            isWinOfDay: isWin,
            createdAt: createdAt
        )
    }
    
    private func ensureCategoryColorExists(for categoryName: String) {
        if getCategoryColor(for: categoryName) == nil {
            // Assign a random color from earthy design system palette
            let colors = [
                "#C75B39", "#4A7C59", "#7A6B8A", "#5B7C8C", "#B8834C",
                "#5A8C8C", "#7A8C8C", "#9C8B7C", "#6B5B6B", "#7C6B5B",
                "#8C7C6B", "#C4B49C", "#9C7C7C", "#6B7B7B", "#D4A853"
            ]
            let randomColor = colors.randomElement() ?? "#4A7C59"
            setCategoryColor(for: categoryName, color: randomColor)
        }
    }
    
    private func insertSampleData() {
        let calendar = Calendar.current
        
        // Get last week's Monday
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let thisMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!
        let lastMonday = calendar.date(byAdding: .day, value: -7, to: thisMonday)!
        
        // Sample entries for last week
        let sampleEntries: [(day: Int, category: String, task: String, time: Double, note: String, isWin: Bool)] = [
            // Monday
            (0, "Reading", "Deep Work by Cal Newport", 1.0, "Finished Chapter 3 on deep work principles", true),
            (0, "Learning", "SwiftUI Advanced Patterns", 1.0, "Learned about preference keys and geometry readers", false),
            (0, "Exercise", "Morning Run", 0.5, "5km in 28 minutes", false),
            
            // Tuesday
            (1, "Reading", "Deep Work by Cal Newport", 0.5, "Chapter 4 on rituals", false),
            (1, "Learning", "Swift Concurrency", 1.5, "Completed async/await tutorial and built sample app", true),
            (1, "Work", "App Feature Development", 2.0, "Implemented the new navigation system", false),
            
            // Wednesday
            (2, "Reading", "Atomic Habits", 0.5, "Started Chapter 1", false),
            (2, "Exercise", "Weight Training", 0.5, "Upper body workout", false),
            (2, "Learning", "SQLite with Swift", 1.0, "Set up database schema and basic queries", true),
            
            // Thursday
            (3, "Work", "Code Review & Refactoring", 1.0, "Refactored the authentication module", false),
            (3, "Learning", "SwiftUI Animation", 1.0, "Practiced matched geometry effects", true),
            (3, "Reading", "Atomic Habits", 0.5, "Chapter 2 on identity-based habits", false),
            
            // Friday
            (4, "Work", "Bug Fixes", 1.0, "Fixed 3 critical bugs from QA", true),
            (4, "Exercise", "Yoga Session", 0.5, "30 minute morning yoga", false),
            (4, "Learning", "Combine Framework", 0.5, "Introduction to publishers and subscribers", false),
            
            // Saturday
            (5, "Personal", "Side Project Work", 1.5, "Built the weekly log feature for Stride", true),
            (5, "Reading", "Atomic Habits", 0.5, "Chapter 3 - the 1% rule", false),
            (5, "Exercise", "Long Run", 1.0, "10km Sunday morning run", true),
            
            // Sunday
            (6, "Personal", "Weekly Planning", 0.5, "Planned goals and tasks for next week", true),
            (6, "Learning", "System Design", 0.5, "Watched video on scalable architectures", false),
            (6, "Reading", "Atomic Habits", 0.5, "Chapter review and notes", false)
        ]
        
        for sample in sampleEntries {
            guard let date = calendar.date(byAdding: .day, value: sample.day, to: lastMonday) else { continue }
            
            let entry = WeeklyLogEntry(
                date: date,
                category: sample.category,
                task: sample.task,
                timeSpent: sample.time,
                progressNote: sample.note,
                isWinOfDay: sample.isWin
            )
            
            createEntry(entry)
        }
        
        // Set specific colors for sample categories - Design System Earthy Palette
        setCategoryColor(for: "Reading", color: "#C75B39")     // Terracotta
        setCategoryColor(for: "Learning", color: "#5B7C8C")    // Slate
        setCategoryColor(for: "Exercise", color: "#4A7C59")    // Moss
        setCategoryColor(for: "Work", color: "#7A6B8A")        // Dusty Purple
        setCategoryColor(for: "Personal", color: "#B8834C")    // Bronze
    }
}
