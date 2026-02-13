import Foundation
import SQLite3
import UserNotifications

/**
 * HabitDatabase - Thread-safe SQLite database manager for habit tracking
 *
 * Manages persistence for habits and habit entries with:
 * - CRUD operations for habits
 * - Entry logging and retrieval
 * - Streak calculation
 * - Statistics aggregation
 * - Daily reminder notifications
 *
 * Thread Safety:
 * All database operations are dispatched to a serial queue to ensure
 * thread-safe access to SQLite.
 */
class HabitDatabase: ObservableObject {
    /// Shared singleton instance
    static let shared = HabitDatabase()
    
    /// SQLite database connection
    private var db: OpaquePointer?
    
    /// Serial dispatch queue for database operations
    private let dbQueue = DispatchQueue(label: "com.stride.habits", qos: .utility)
    
    /// Path to the SQLite database file
    private let dbPath: String = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls.first!.appendingPathComponent("Stride")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("habits.db").path
    }()
    
    /// Published property to notify UI of changes
    @Published private(set) var lastUpdate = Date()
    
    private init() {
        openDatabase()
        if db != nil {
            createTables()
            initializeSampleHabits()
            // Note: Notification permissions are requested in AppDelegate
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
            print("Error opening habits database")
            db = nil
        }
    }
    
    private func createTables() {
        let createHabitsTable = """
            CREATE TABLE IF NOT EXISTS habits (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT NOT NULL,
                color TEXT NOT NULL,
                type TEXT NOT NULL,
                frequency TEXT NOT NULL,
                target_value REAL NOT NULL DEFAULT 1.0,
                reminder_time REAL,
                reminder_enabled INTEGER NOT NULL DEFAULT 0,
                created_at REAL NOT NULL,
                is_archived INTEGER NOT NULL DEFAULT 0
            );
        """
        
        let createEntriesTable = """
            CREATE TABLE IF NOT EXISTS habit_entries (
                id TEXT PRIMARY KEY,
                habit_id TEXT NOT NULL,
                date REAL NOT NULL,
                value REAL NOT NULL DEFAULT 0.0,
                notes TEXT,
                created_at REAL NOT NULL,
                FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
            );
        """
        
        let createIndex = """
            CREATE INDEX IF NOT EXISTS idx_entries_habit_date 
            ON habit_entries(habit_id, date);
        """
        
        execute(createHabitsTable)
        execute(createEntriesTable)
        execute(createIndex)
    }
    
    private func execute(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let message = String(cString: errorMessage!)
            print("Habits SQL Error: \(message)")
            sqlite3_free(errorMessage)
        }
    }
    
    // MARK: - Sample Data Initialization
    
    private func initializeSampleHabits() {
        let existingHabits = getAllHabits()
        guard existingHabits.isEmpty else { return }
        
        for habit in Habit.sampleHabits {
            createHabit(habit)
        }
    }
    
    // MARK: - Habit CRUD Operations
    
    func createHabit(_ habit: Habit) {
        let sql = """
            INSERT INTO habits (id, name, icon, color, type, frequency, target_value, reminder_time, reminder_enabled, created_at, is_archived)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (habit.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (habit.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (habit.icon as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (habit.color as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 5, (habit.type.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 6, (habit.frequency.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 7, habit.targetValue)
                if let reminderTime = habit.reminderTime {
                    sqlite3_bind_double(statement, 8, reminderTime.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(statement, 8)
                }
                sqlite3_bind_int(statement, 9, habit.reminderEnabled ? 1 : 0)
                sqlite3_bind_double(statement, 10, habit.createdAt.timeIntervalSince1970)
                sqlite3_bind_int(statement, 11, habit.isArchived ? 1 : 0)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async {
                self.lastUpdate = Date()
                if habit.reminderEnabled {
                    self.scheduleReminder(for: habit)
                }
            }
        }
    }
    
    func updateHabit(_ habit: Habit) {
        let sql = """
            UPDATE habits
            SET name = ?, icon = ?, color = ?, type = ?, frequency = ?, target_value = ?, 
                reminder_time = ?, reminder_enabled = ?, is_archived = ?
            WHERE id = ?;
        """
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (habit.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (habit.icon as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (habit.color as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (habit.type.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 5, (habit.frequency.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 6, habit.targetValue)
                if let reminderTime = habit.reminderTime {
                    sqlite3_bind_double(statement, 7, reminderTime.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(statement, 7)
                }
                sqlite3_bind_int(statement, 8, habit.reminderEnabled ? 1 : 0)
                sqlite3_bind_int(statement, 9, habit.isArchived ? 1 : 0)
                sqlite3_bind_text(statement, 10, (habit.id.uuidString as NSString).utf8String, -1, nil)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async {
                self.lastUpdate = Date()
                self.scheduleReminder(for: habit)
            }
        }
    }
    
    func deleteHabit(id: UUID) {
        let sql = "DELETE FROM habits WHERE id = ?;"
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async {
                self.lastUpdate = Date()
                self.removeReminder(for: id)
            }
        }
    }
    
    func getAllHabits() -> [Habit] {
        guard db != nil else { return [] }
        
        let sql = "SELECT * FROM habits ORDER BY created_at DESC;"
        
        return dbQueue.sync {
            var habits: [Habit] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let habit = extractHabit(from: statement!) {
                        habits.append(habit)
                    }
                }
            }
            sqlite3_finalize(statement)
            return habits
        }
    }
    
    func getHabit(byId id: UUID) -> Habit? {
        guard db != nil else { return nil }
        
        let sql = "SELECT * FROM habits WHERE id = ?;"
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            var result: Habit? = nil
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id.uuidString as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = extractHabit(from: statement!)
                }
            }
            sqlite3_finalize(statement)
            return result
        }
    }
    
    private func extractHabit(from statement: OpaquePointer) -> Habit? {
        guard let idString = sqlite3_column_text(statement, 0),
              let nameString = sqlite3_column_text(statement, 1),
              let iconString = sqlite3_column_text(statement, 2),
              let colorString = sqlite3_column_text(statement, 3),
              let typeString = sqlite3_column_text(statement, 4),
              let frequencyString = sqlite3_column_text(statement, 5) else {
            return nil
        }
        
        let id = UUID(uuidString: String(cString: idString))!
        let name = String(cString: nameString)
        let icon = String(cString: iconString)
        let color = String(cString: colorString)
        let type = HabitType(rawValue: String(cString: typeString)) ?? .checkbox
        let frequency = HabitFrequency(rawValue: String(cString: frequencyString)) ?? .daily
        let targetValue = sqlite3_column_double(statement, 6)
        let reminderTime: Date? = sqlite3_column_type(statement, 7) != SQLITE_NULL 
            ? Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
            : nil
        let reminderEnabled = sqlite3_column_int(statement, 8) == 1
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 9))
        let isArchived = sqlite3_column_int(statement, 10) == 1
        
        return Habit(
            id: id,
            name: name,
            icon: icon,
            color: color,
            type: type,
            frequency: frequency,
            targetValue: targetValue,
            reminderTime: reminderTime,
            reminderEnabled: reminderEnabled,
            createdAt: createdAt,
            isArchived: isArchived
        )
    }
    
    // MARK: - Entry Operations
    
    func addEntry(_ entry: HabitEntry) {
        let sql = """
            INSERT OR REPLACE INTO habit_entries (id, habit_id, date, value, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (entry.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (entry.habitId.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 3, entry.date.timeIntervalSince1970)
                sqlite3_bind_double(statement, 4, entry.value)
                sqlite3_bind_text(statement, 5, (entry.notes as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 6, entry.createdAt.timeIntervalSince1970)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async {
                self.lastUpdate = Date()
            }
        }
    }
    
    func deleteEntry(id: UUID) {
        let sql = "DELETE FROM habit_entries WHERE id = ?;"
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async {
                self.lastUpdate = Date()
            }
        }
    }
    
    func getEntries(for habitId: UUID, from startDate: Date? = nil, to endDate: Date? = nil) -> [HabitEntry] {
        guard db != nil else { return [] }
        
        var sql = "SELECT * FROM habit_entries WHERE habit_id = ?"
        var params: [Any] = [habitId.uuidString]
        
        if let start = startDate {
            sql += " AND date >= ?"
            params.append(start.timeIntervalSince1970)
        }
        if let end = endDate {
            sql += " AND date <= ?"
            params.append(end.timeIntervalSince1970)
        }
        
        sql += " ORDER BY date DESC;"
        
        return dbQueue.sync {
            var entries: [HabitEntry] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                for (index, param) in params.enumerated() {
                    let position = Int32(index + 1)
                    if let str = param as? String {
                        sqlite3_bind_text(statement, position, (str as NSString).utf8String, -1, nil)
                    } else if let double = param as? Double {
                        sqlite3_bind_double(statement, position, double)
                    }
                }
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let entry = extractEntry(from: statement!) {
                        entries.append(entry)
                    }
                }
            }
            sqlite3_finalize(statement)
            return entries
        }
    }
    
    func getEntry(for habitId: UUID, on date: Date) -> HabitEntry? {
        guard db != nil else { return nil }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let sql = """
            SELECT * FROM habit_entries 
            WHERE habit_id = ? AND date >= ? AND date < ?
            ORDER BY created_at DESC
            LIMIT 1;
        """
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            var result: HabitEntry? = nil
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (habitId.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 2, startOfDay.timeIntervalSince1970)
                sqlite3_bind_double(statement, 3, endOfDay.timeIntervalSince1970)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = extractEntry(from: statement!)
                }
            }
            sqlite3_finalize(statement)
            return result
        }
    }
    
    private func extractEntry(from statement: OpaquePointer) -> HabitEntry? {
        guard let idString = sqlite3_column_text(statement, 0),
              let habitIdString = sqlite3_column_text(statement, 1) else {
            return nil
        }
        
        let id = UUID(uuidString: String(cString: idString))!
        let habitId = UUID(uuidString: String(cString: habitIdString))!
        let date = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
        let value = sqlite3_column_double(statement, 3)
        let notes = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? ""
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
        
        return HabitEntry(
            id: id,
            habitId: habitId,
            date: date,
            value: value,
            notes: notes,
            createdAt: createdAt
        )
    }
    
    // MARK: - Streak Calculations
    
    func getStreak(for habit: Habit) -> HabitStreak {
        let entries = getEntries(for: habit.id)
        
        guard !entries.isEmpty else {
            return HabitStreak()
        }
        
        // Sort entries by date
        let sortedEntries = entries.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var lastDate: Date?
        var lastCompletedDate: Date?
        
        // Group entries by day and check completion
        var entriesByDay: [Date: [HabitEntry]] = [:]
        for entry in sortedEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            entriesByDay[dayStart, default: []].append(entry)
        }
        
        let sortedDays = entriesByDay.keys.sorted(by: >)
        
        for day in sortedDays {
            let dayEntries = entriesByDay[day]!
            let isCompleted = isHabitCompleted(habit: habit, entries: dayEntries)
            
            if isCompleted {
                longestStreak = max(longestStreak, tempStreak + 1)
                tempStreak += 1
                lastCompletedDate = day
                
                // Check if this contributes to current streak
                if lastDate == nil || calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: lastDate!)!) {
                    currentStreak = tempStreak
                }
                
                lastDate = day
            } else {
                tempStreak = 0
                if currentStreak > 0 {
                    // Streak was broken
                    break
                }
            }
        }
        
        return HabitStreak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCompletedDate: lastCompletedDate
        )
    }
    
    private func isHabitCompleted(habit: Habit, entries: [HabitEntry]) -> Bool {
        switch habit.type {
        case .checkbox:
            return entries.contains { $0.isCompleted }
        case .timer, .counter:
            let total = entries.reduce(0) { $0 + $1.value }
            return total >= habit.targetValue
        }
    }
    
    // MARK: - Statistics
    
    func getStatistics(for habit: Habit) -> HabitStatistics {
        let entries = getEntries(for: habit.id)
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate basic stats
        let totalEntries = entries.count
        let totalValue = entries.reduce(0) { $0 + $1.value }
        let averageValue = totalEntries > 0 ? totalValue / Double(totalEntries) : 0
        
        // Calculate completion rate (last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        var completedDays = 0
        var totalDays = 0
        
        var currentDate = thirtyDaysAgo
        while currentDate <= today {
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            if !dayEntries.isEmpty {
                totalDays += 1
                if isHabitCompleted(habit: habit, entries: dayEntries) {
                    completedDays += 1
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let completionRate = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
        
        // Get streak
        let streak = getStreak(for: habit)
        
        // Weekly data (last 7 days)
        var weeklyData: [Date: Double] = [:]
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                weeklyData[dayStart] = dayEntries.reduce(0) { $0 + $1.value }
            }
        }
        
        // Monthly data (last 30 days)
        var monthlyData: [Date: Double] = [:]
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                monthlyData[dayStart] = dayEntries.reduce(0) { $0 + $1.value }
            }
        }
        
        return HabitStatistics(
            habit: habit,
            totalEntries: totalEntries,
            completionRate: completionRate,
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            totalValue: totalValue,
            averageValue: averageValue,
            weeklyData: weeklyData,
            monthlyData: monthlyData
        )
    }
    
    // MARK: - Reminder Notifications
    
    // Note: UserNotifications disabled for Swift Package Manager builds
    // These methods are stubs for Xcode builds with proper app bundle
    
    func scheduleReminder(for habit: Habit) {
        // UserNotifications require proper app bundle configuration
        // This feature is disabled for Swift Package Manager builds
    }
    
    func removeReminder(for habitId: UUID) {
        // UserNotifications require proper app bundle configuration
        // This feature is disabled for Swift Package Manager builds
    }
    
    func checkAndSendReminders() {
        // UserNotifications require proper app bundle configuration
        // This feature is disabled for Swift Package Manager builds
    }
}