import Foundation
import SQLite3
import UserNotifications
import os.log

// MARK: - Habit Database Migrations

struct HabitMigrationV1: DatabaseMigration {
    let version = 1
    let description = "Initial schema with habits and habit_entries tables"
    
    func execute(on db: OpaquePointer) throws {
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
        
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(db, createHabitsTable, nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            throw DatabaseError.executeFailed(sql: createHabitsTable, message: msg)
        }
        
        if sqlite3_exec(db, createEntriesTable, nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            throw DatabaseError.executeFailed(sql: createEntriesTable, message: msg)
        }
        
        if sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_entries_habit_date ON habit_entries(habit_id, date);", nil, nil, &errorMessage) != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            errorMessage.map { sqlite3_free($0) }
            throw DatabaseError.executeFailed(sql: "CREATE INDEX", message: msg)
        }
    }
}

// MARK: - Habit Database Error (Backward Compatibility)

typealias HabitDatabaseResult<T> = Result<T, DatabaseError>

// MARK: - Habit Database

final class HabitDatabase: BaseDatabase, ObservableObject {
    
    static let shared = HabitDatabase()
    
    @Published private(set) var lastUpdate = Date()
    
    private let migrations: [DatabaseMigration] = [
        HabitMigrationV1()
    ]
    
    private init() {
        super.init(filename: "habits.db", queueLabel: "com.stride.habits")
        
        switch openDatabase() {
        case .success:
            _ = runMigrations(migrations)
            initializeSampleHabits()
        case .failure(let error):
            DatabaseLogger.error.error("Failed to initialize HabitDatabase: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Thread-Safe Operations
    
    // PERFORMANCE NOTE: For 10-20 habits with 91-day grids, current implementation is sufficient.
    // If scaling to 50+ habits, consider:
    // 1. Batch operations: Queue multiple increments/decrements into single transaction
    // 2. Lazy loading: Only load visible date ranges
    // 3. Virtual scrolling: Render only visible habit cards
    // 4. Background streak calculation: Move to background thread with caching
    
    func incrementEntry(habitId: UUID, date: Date) -> HabitDatabaseResult<Void> {
        return dbQueue.sync {
            guard let db = db else { return .failure(.databaseNotInitialized) }
            
            // Normalize date to start of day for consistency (handles DST/timezone)
            let normalizedDate = Calendar.current.startOfDay(for: date)
            
            let existing = unsafeGetEntry(for: habitId, on: normalizedDate)
            
            if let entry = existing {
                let newValue = entry.value + 1.0
                let sql = "UPDATE habit_entries SET value = ?, created_at = ? WHERE id = ?;"
                var statement: OpaquePointer?
                
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                    return .failure(.queryFailed(sql: sql, message: "Prepare failed"))
                }
                
                sqlite3_bind_double(statement, 1, newValue)
                sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 3, (entry.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            } else {
                let entry = HabitEntry(habitId: habitId, date: normalizedDate, value: 1.0)
                unsafeAddEntry(entry)
            }
            
            DispatchQueue.main.async { self.lastUpdate = Date() }
            return .success(())
        }
    }
    
    func decrementEntry(habitId: UUID, date: Date) -> HabitDatabaseResult<Void> {
        return dbQueue.sync {
            guard let db = db else { return .failure(.databaseNotInitialized) }
            
            // Normalize date to start of day for consistency (handles DST/timezone)
            let normalizedDate = Calendar.current.startOfDay(for: date)
            
            guard let entry = unsafeGetEntry(for: habitId, on: normalizedDate) else {
                return .success(())
            }
            
            let newValue = entry.value - 1.0
            
            // If decrementing to zero, delete the entry entirely
            if newValue <= 0 {
                let sql = "DELETE FROM habit_entries WHERE id = ?;"
                var statement: OpaquePointer?
                
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                    return .failure(.queryFailed(sql: sql, message: "Prepare failed"))
                }
                
                sqlite3_bind_text(statement, 1, (entry.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            } else {
                // Otherwise, update the value
                let sql = "UPDATE habit_entries SET value = ?, created_at = ? WHERE id = ?;"
                var statement: OpaquePointer?
                
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                    return .failure(.queryFailed(sql: sql, message: "Prepare failed"))
                }
                
                sqlite3_bind_double(statement, 1, newValue)
                sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 3, (entry.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
            
            DispatchQueue.main.async { self.lastUpdate = Date() }
            return .success(())
        }
    }
    
    func addEntry(_ entry: HabitEntry) -> HabitDatabaseResult<Void> {
        return dbQueue.sync {
            unsafeAddEntry(entry)
            DispatchQueue.main.async { self.lastUpdate = Date() }
            return .success(())
        }
    }
    
    func getEntry(for habitId: UUID, on date: Date) -> HabitEntry? {
        return dbQueue.sync { unsafeGetEntry(for: habitId, on: date) }
    }
    
    func deleteEntry(id: UUID) -> HabitDatabaseResult<Void> {
        return dbQueue.sync {
            guard let db = db else { return .failure(.databaseNotInitialized) }
            
            let sql = "DELETE FROM habit_entries WHERE id = ?;"
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return .failure(.queryFailed(sql: sql, message: "Prepare failed"))
            }
            
            sqlite3_bind_text(statement, 1, (id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async { self.lastUpdate = Date() }
            return .success(())
        }
    }
    
    func getEntries(for habitId: UUID, from startDate: Date? = nil, to endDate: Date? = nil) -> [HabitEntry] {
        return dbQueue.sync {
            guard let db = db else { return [] }
            
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
            
            var entries: [HabitEntry] = []
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return entries
            }
            
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
            
            sqlite3_finalize(statement)
            return entries
        }
    }
    
    // MARK: - Habit CRUD
    
    func createHabit(_ habit: Habit) -> HabitDatabaseResult<Void> {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else { return }
            
            let sql = "INSERT INTO habits (id, name, icon, color, type, frequency, target_value, reminder_time, reminder_enabled, created_at, is_archived) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                DatabaseLogger.error.error("Failed to prepare create habit statement")
                return
            }
            
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
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async { self.lastUpdate = Date() }
        }
        return .success(())
    }
    
    func updateHabit(_ habit: Habit) -> HabitDatabaseResult<Void> {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else { return }
            
            let sql = "UPDATE habits SET name = ?, icon = ?, color = ?, type = ?, frequency = ?, target_value = ?, reminder_time = ?, reminder_enabled = ?, is_archived = ? WHERE id = ?;"
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                DatabaseLogger.error.error("Failed to prepare update habit statement")
                return
            }
            
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
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async { self.lastUpdate = Date() }
        }
        return .success(())
    }
    
    func deleteHabit(id: UUID) -> HabitDatabaseResult<Void> {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else { return }
            
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, "DELETE FROM habits WHERE id = ?;", -1, &statement, nil) == SQLITE_OK else {
                return
            }
            
            sqlite3_bind_text(statement, 1, (id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
            
            DispatchQueue.main.async { self.lastUpdate = Date() }
        }
        return .success(())
    }
    
    func getAllHabits() -> [Habit] {
        return dbQueue.sync {
            guard let db = db else { return [] }
            
            var habits: [Habit] = []
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, "SELECT * FROM habits ORDER BY created_at DESC;", -1, &statement, nil) == SQLITE_OK else {
                return habits
            }
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let habit = extractHabit(from: statement!) {
                    habits.append(habit)
                }
            }
            
            sqlite3_finalize(statement)
            return habits
        }
    }
    
    func getHabit(byId id: UUID) -> Habit? {
        return dbQueue.sync {
            guard let db = db else { return nil }
            
            var statement: OpaquePointer?
            var result: Habit?
            
            guard sqlite3_prepare_v2(db, "SELECT * FROM habits WHERE id = ?;", -1, &statement, nil) == SQLITE_OK else {
                return nil
            }
            
            sqlite3_bind_text(statement, 1, (id.uuidString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                result = extractHabit(from: statement!)
            }
            
            sqlite3_finalize(statement)
            return result
        }
    }
    
    // MARK: - Statistics
    
    func getStreak(for habit: Habit) -> HabitStreak {
        let entries = getEntries(for: habit.id)
        guard !entries.isEmpty else { return HabitStreak() }
        
        let sortedEntries = entries.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var lastDate: Date?
        var lastCompletedDate: Date?
        
        var entriesByDay: [Date: [HabitEntry]] = [:]
        for entry in sortedEntries {
            entriesByDay[calendar.startOfDay(for: entry.date), default: []].append(entry)
        }
        
        for day in entriesByDay.keys.sorted(by: >) {
            if isHabitCompleted(habit: habit, entries: entriesByDay[day]!) {
                longestStreak = max(longestStreak, tempStreak + 1)
                tempStreak += 1
                lastCompletedDate = day
                if lastDate == nil || calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: lastDate!)!) {
                    currentStreak = tempStreak
                }
                lastDate = day
            } else {
                tempStreak = 0
                if currentStreak > 0 { break }
            }
        }
        
        return HabitStreak(currentStreak: currentStreak, longestStreak: longestStreak, lastCompletedDate: lastCompletedDate)
    }
    
    func getStatistics(for habit: Habit) -> HabitStatistics {
        let entries = getEntries(for: habit.id)
        let calendar = Calendar.current
        let today = Date()
        
        let totalEntries = entries.count
        let totalValue = entries.reduce(0) { $0 + $1.value }
        let averageValue = totalEntries > 0 ? totalValue / Double(totalEntries) : 0
        
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
        
        let streak = getStreak(for: habit)
        var weeklyData: [Date: Double] = [:]
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                weeklyData[calendar.startOfDay(for: date)] = entries
                    .filter { calendar.isDate($0.date, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.value }
            }
        }
        
        return HabitStatistics(
            habit: habit,
            totalEntries: totalEntries,
            completionRate: totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0,
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            totalValue: totalValue,
            averageValue: averageValue,
            weeklyData: weeklyData,
            monthlyData: [:]
        )
    }
    
    // MARK: - Private Helpers
    
    private func unsafeAddEntry(_ entry: HabitEntry) {
        guard let db = db else { return }
        
        let sql = "INSERT OR REPLACE INTO habit_entries (id, habit_id, date, value, notes, created_at) VALUES (?, ?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        
        sqlite3_bind_text(statement, 1, (entry.id.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (entry.habitId.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_double(statement, 3, entry.date.timeIntervalSince1970)
        sqlite3_bind_double(statement, 4, entry.value)
        sqlite3_bind_text(statement, 5, (entry.notes as NSString).utf8String, -1, nil)
        sqlite3_bind_double(statement, 6, entry.createdAt.timeIntervalSince1970)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }
    
    private func unsafeGetEntry(for habitId: UUID, on date: Date) -> HabitEntry? {
        guard let db = db else { return nil }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let sql = "SELECT * FROM habit_entries WHERE habit_id = ? AND date >= ? AND date < ? ORDER BY created_at DESC LIMIT 1;"
        var statement: OpaquePointer?
        var result: HabitEntry?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        
        sqlite3_bind_text(statement, 1, (habitId.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_double(statement, 2, startOfDay.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, endOfDay.timeIntervalSince1970)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            result = extractEntry(from: statement!)
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    private func extractEntry(from statement: OpaquePointer) -> HabitEntry? {
        guard let idString = sqlite3_column_text(statement, 0),
              let habitIdString = sqlite3_column_text(statement, 1) else { return nil }
        
        guard let id = UUID(uuidString: String(cString: idString)),
              let habitId = UUID(uuidString: String(cString: habitIdString)) else {
            return nil
        }
        
        return HabitEntry(
            id: id,
            habitId: habitId,
            date: Date(timeIntervalSince1970: sqlite3_column_double(statement, 2)),
            value: sqlite3_column_double(statement, 3),
            notes: sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? "",
            createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
        )
    }
    
    private func extractHabit(from statement: OpaquePointer) -> Habit? {
        guard let idString = sqlite3_column_text(statement, 0),
              let nameString = sqlite3_column_text(statement, 1),
              let iconString = sqlite3_column_text(statement, 2),
              let colorString = sqlite3_column_text(statement, 3),
              let typeString = sqlite3_column_text(statement, 4),
              let frequencyString = sqlite3_column_text(statement, 5) else { return nil }
        
        guard let id = UUID(uuidString: String(cString: idString)) else { return nil }
        
        return Habit(
            id: id,
            name: String(cString: nameString),
            icon: String(cString: iconString),
            color: String(cString: colorString),
            type: HabitType(rawValue: String(cString: typeString)) ?? .checkbox,
            frequency: HabitFrequency(rawValue: String(cString: frequencyString)) ?? .daily,
            targetValue: sqlite3_column_double(statement, 6),
            reminderTime: sqlite3_column_type(statement, 7) != SQLITE_NULL ? Date(timeIntervalSince1970: sqlite3_column_double(statement, 7)) : nil,
            reminderEnabled: sqlite3_column_int(statement, 8) == 1,
            createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 9)),
            isArchived: sqlite3_column_int(statement, 10) == 1
        )
    }
    
    private func isHabitCompleted(habit: Habit, entries: [HabitEntry]) -> Bool {
        if habit.type == .checkbox { return entries.contains { $0.isCompleted } }
        return entries.reduce(0) { $0 + $1.value } > 0
    }
    
    private func initializeSampleHabits() {
        if getAllHabits().isEmpty {
            for habit in Habit.sampleHabits {
                _ = createHabit(habit)
            }
        }
    }
    
    // MARK: - Stubs
    
    func scheduleReminder(for habit: Habit) {}
    func removeReminder(for habitId: UUID) {}
    func checkAndSendReminders() {}
}
