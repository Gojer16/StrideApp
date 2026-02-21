import Foundation
import SQLite3
import SwiftUI

// MARK: - Category Model

/**
 Represents a user-defined category for organizing applications.
 
 Categories allow users to group apps (e.g., "Work", "Entertainment", "Development")
 for better time tracking insights.
 
 **Default Categories:**
 The app comes with 8 predefined categories that cover common use cases.
 Users can create custom categories as needed.
 */
struct Category: Codable, Identifiable, Hashable {
    static let uncategorizedId = "00000000-0000-0000-0000-000000000008"
    
    let id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var color: String // Hex color code
    var order: Int    // Display order in UI
    var isDefault: Bool // Cannot delete default categories
    
    init(id: UUID = UUID(), name: String, icon: String, color: String, order: Int = 0, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.order = order
        self.isDefault = isDefault
    }
    
    /// Predefined categories available on first launch
    static let defaultCategories: [Category] = [
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Work", icon: "briefcase.fill", color: "#C75B39", order: 0, isDefault: true),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Entertainment", icon: "play.circle.fill", color: "#7A6B8A", order: 1, isDefault: true),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Social", icon: "person.2.fill", color: "#5B7C8C", order: 2, isDefault: true),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Productivity", icon: "checkmark.circle.fill", color: "#4A7C59", order: 3, isDefault: true),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Development", icon: "chevron.left.forwardslash.chevron.right", color: "#B8834C", order: 4, isDefault: true),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "Communication", icon: "message.fill", color: "#5A8C7C", order: 5, isDefault: true),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "Utilities", icon: "wrench.fill", color: "#7A8C8C", order: 6, isDefault: true),
        Category(id: UUID(uuidString: uncategorizedId)!, name: "Uncategorized", icon: "questionmark.circle.fill", color: "#6B7B7B", order: 999, isDefault: true)
    ]
}

// MARK: - Legacy Enum (for migration)

/**
 Legacy category enum for database migration.
 
 Previously categories were stored as enum strings. This enum is kept
 for migrating old data to the new dynamic category system.
 
 **Note:** New code should use `Category` struct instead.
 */
enum AppCategory: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    
    case work = "Work"
    case entertainment = "Entertainment"
    case social = "Social"
    case productivity = "Productivity"
    case development = "Development"
    case communication = "Communication"
    case utilities = "Utilities"
    case uncategorized = "Uncategorized"
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .entertainment: return "play.circle.fill"
        case .social: return "person.2.fill"
        case .productivity: return "checkmark.circle.fill"
        case .development: return "chevron.left.forwardslash.chevron.right"
        case .communication: return "message.fill"
        case .utilities: return "wrench.fill"
        case .uncategorized: return "questionmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .work: return "#FF6B6B"
        case .entertainment: return "#9B59B6"
        case .social: return "#3498DB"
        case .productivity: return "#27AE60"
        case .development: return "#E67E22"
        case .communication: return "#1ABC9C"
        case .utilities: return "#95A5A6"
        case .uncategorized: return "#7F8C8D"
        }
    }
}

// MARK: - Data Models

/**
 Represents an application's usage statistics.
 
 Tracks aggregate data across all windows of an application:
 - Total time spent
 - Visit count
 - First/last seen dates
 - Assigned category
 */
struct AppUsage: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var categoryId: String
    var firstSeen: Date
    var lastSeen: Date
    var totalTimeSpent: TimeInterval
    var visitCount: Int
    var windows: [WindowUsage] // Not persisted directly (separate table)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppUsage, rhs: AppUsage) -> Bool {
        lhs.id == rhs.id
    }
    
    init(name: String, categoryId: String = "") {
        self.id = UUID()
        self.name = name
        self.categoryId = categoryId.isEmpty ? Category.uncategorizedId : categoryId
        self.firstSeen = Date()
        self.lastSeen = Date()
        self.totalTimeSpent = 0
        self.visitCount = 1
        self.windows = []
    }
    
    init(id: UUID, name: String, categoryId: String, firstSeen: Date, lastSeen: Date, totalTimeSpent: TimeInterval, visitCount: Int, windows: [WindowUsage]) {
        self.id = id
        self.name = name
        self.categoryId = categoryId
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.totalTimeSpent = totalTimeSpent
        self.visitCount = visitCount
        self.windows = windows
    }
    
    func getCategory() -> Category {
        return UsageDatabase.shared.getCategory(byId: categoryId) ?? Category.defaultCategories.last!
    }
}

/**
 Represents a specific window's usage statistics within an application.
 
 Different windows of the same app (e.g., different browser tabs) are tracked
 separately to provide granular time tracking.
 */
struct WindowUsage: Codable, Identifiable {
    let id: UUID
    var title: String
    var firstSeen: Date
    var lastSeen: Date
    var totalTimeSpent: TimeInterval
    var visitCount: Int
    var sessions: [UsageSession] // Not persisted directly (separate table)
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.firstSeen = Date()
        self.lastSeen = Date()
        self.totalTimeSpent = 0
        self.visitCount = 1
        self.sessions = []
    }
    
    init(id: UUID, title: String, firstSeen: Date, lastSeen: Date, totalTimeSpent: TimeInterval, visitCount: Int, sessions: [UsageSession]) {
        self.id = id
        self.title = title
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.totalTimeSpent = totalTimeSpent
        self.visitCount = visitCount
        self.sessions = sessions
    }
}

/**
 Represents a single continuous usage session.
 
 A session tracks the time spent continuously in one window.
 Sessions end when the user switches apps or windows.
 
 **Lifecycle:**
 1. Created when user focuses a window
 2. Updated with end time when user switches away
 3. Duration calculated from start to end
 */
struct UsageSession: Codable, Identifiable {
    let id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    
    init() {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.duration = 0
    }
    
    mutating func end() {
        self.endTime = Date()
        self.duration = endTime?.timeIntervalSince(startTime) ?? 0
    }
}

// MARK: - SQLite Database Manager

/**
 Thread-safe SQLite database manager for storing usage statistics.
 
 **Thread Safety:**
 All database operations are dispatched to a serial queue (`dbQueue`) to ensure
 thread safety. SQLite is not thread-safe by default, so this prevents:
 - Concurrent write conflicts
 - Data corruption
 - Crashes from multi-threaded access
 
 **Operation Types:**
 - **Sync operations** (`dbQueue.sync`): For methods that return values (reads and creates)
 - **Async operations** (`dbQueue.async`): For fire-and-forget updates (writes)
 
 **Database Schema:**
 - `categories`: User-defined app categories
 - `applications`: Tracked applications with metadata
 - `windows`: Individual windows within apps
 - `sessions`: Time tracking sessions
 */
class UsageDatabase {
    /// Shared singleton instance
    static let shared = UsageDatabase()
    
    /// SQLite database connection
    private var db: OpaquePointer?
    
    /**
     Serial dispatch queue for database operations.
     
     Using a serial queue ensures all database operations happen sequentially,
     preventing race conditions and data corruption. The `.utility` QoS
     prioritizes energy efficiency over speed.
     */
    private let dbQueue = DispatchQueue(label: "com.stride.database", qos: .utility)
    
    /// Path to the SQLite database file in Application Support
    private let dbPath: String = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls.first!.appendingPathComponent("Stride")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("usage.db").path
    }()
    
    private init() {
        openDatabase()
        if db != nil {
            createTables()
            migrateDatabaseIfNeeded()
            initializeDefaultCategories()
        } else {
            print("Failed to initialize database - operations will be no-ops")
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
            print("Error opening database at path: \(dbPath)")
            db = nil
        }
    }
    
    /**
     Creates database tables if they don't exist.
     
     Schema:
     - categories: Stores category definitions
     - applications: App usage aggregates (with foreign key to categories)
     - windows: Window usage aggregates (with foreign key to applications)
     - sessions: Individual tracking sessions (with foreign key to windows)
     */
    private func createTables() {
        let createCategoriesTable = """
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                name TEXT UNIQUE NOT NULL,
                icon TEXT NOT NULL DEFAULT 'folder',
                color TEXT NOT NULL DEFAULT '#7F8C8D',
                sort_order INTEGER NOT NULL DEFAULT 0,
                is_default INTEGER NOT NULL DEFAULT 0
            );
        """
        
        let createAppsTable = """
            CREATE TABLE IF NOT EXISTS applications (
                id TEXT PRIMARY KEY,
                name TEXT UNIQUE NOT NULL,
                category_id TEXT DEFAULT 'uncategorized',
                first_seen REAL NOT NULL,
                last_seen REAL NOT NULL,
                total_time_spent REAL NOT NULL DEFAULT 0,
                visit_count INTEGER NOT NULL DEFAULT 1,
                FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET DEFAULT
            );
        """
        
        let createWindowsTable = """
            CREATE TABLE IF NOT EXISTS windows (
                id TEXT PRIMARY KEY,
                app_id TEXT NOT NULL,
                title TEXT NOT NULL,
                first_seen REAL NOT NULL,
                last_seen REAL NOT NULL,
                total_time_spent REAL NOT NULL DEFAULT 0,
                visit_count INTEGER NOT NULL DEFAULT 1,
                UNIQUE(app_id, title),
                FOREIGN KEY (app_id) REFERENCES applications(id) ON DELETE CASCADE
            );
        """
        
        let createSessionsTable = """
            CREATE TABLE IF NOT EXISTS sessions (
                id TEXT PRIMARY KEY,
                window_id TEXT NOT NULL,
                start_time REAL NOT NULL,
                end_time REAL,
                duration REAL NOT NULL DEFAULT 0,
                FOREIGN KEY (window_id) REFERENCES windows(id) ON DELETE CASCADE
            );
        """
        
        execute(createCategoriesTable)
        execute(createAppsTable)
        execute(createWindowsTable)
        execute(createSessionsTable)
    }
    
    /**
     Migrates from old category system to new dynamic categories.
     
     Legacy versions stored category as a string enum. This migration:
     1. Checks if category_id column exists
     2. Creates it if missing
     3. Migrates old category names to category_id references
     */
    private func migrateDatabaseIfNeeded() {
        let checkColumnSQL = "PRAGMA table_info(applications);"
        var statement: OpaquePointer?
        var hasCategoryIdColumn = false
        var hasOldCategoryColumn = false
        
        if sqlite3_prepare_v2(db, checkColumnSQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let columnName = sqlite3_column_text(statement, 1) {
                    let name = String(cString: columnName)
                    if name == "category_id" {
                        hasCategoryIdColumn = true
                    }
                    if name == "category" {
                        hasOldCategoryColumn = true
                    }
                }
            }
        }
        sqlite3_finalize(statement)
        
        if !hasCategoryIdColumn {
            if hasOldCategoryColumn {
                let migrateSQL = """
                    ALTER TABLE applications ADD COLUMN category_id TEXT DEFAULT '\(Category.uncategorizedId.lowercased())';
                    UPDATE applications SET category_id = LOWER(REPLACE(category, ' ', '_')) WHERE category_id = '\(Category.uncategorizedId.lowercased())';
                """
                execute(migrateSQL)
            } else {
                let addColumnSQL = "ALTER TABLE applications ADD COLUMN category_id TEXT DEFAULT '\(Category.uncategorizedId.lowercased())';"
                execute(addColumnSQL)
            }
        }
        
        // Ensure all IDs are lowercase and literal "uncategorized" is converted
        let fixCaseSQL = "UPDATE applications SET category_id = LOWER(category_id);"
        execute(fixCaseSQL)
        let fixUncategorizedSQL = "UPDATE applications SET category_id = '\(Category.uncategorizedId.lowercased())' WHERE category_id = 'uncategorized';"
        execute(fixUncategorizedSQL)
    }
    
    private func initializeDefaultCategories() {
        let existingCategories = getAllCategories()
        if existingCategories.isEmpty {
            for category in Category.defaultCategories {
                createCategory(category)
            }
        }
    }
    
    private func execute(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let message = String(cString: errorMessage!)
            print("SQL Error: \(message)")
            sqlite3_free(errorMessage)
        }
    }
    
    // MARK: - Category CRUD Operations
    
    func createCategory(_ category: Category) {
        let sql = """
            INSERT OR REPLACE INTO categories (id, name, icon, color, sort_order, is_default)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (category.id.uuidString.lowercased() as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (category.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (category.icon as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (category.color as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 5, Int32(category.order))
            sqlite3_bind_int(statement, 6, category.isDefault ? 1 : 0)
            
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func updateCategory(_ category: Category) {
        let sql = """
            UPDATE categories
            SET name = ?, icon = ?, color = ?, sort_order = ?
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (category.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (category.icon as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (category.color as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, Int32(category.order))
            sqlite3_bind_text(statement, 5, (category.id.uuidString.lowercased() as NSString).utf8String, -1, nil)
            
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func deleteCategory(id: String) {
        guard let category = getCategory(byId: id), !category.isDefault else { return }
        
        let updateAppsSQL = "UPDATE applications SET category_id = '\(Category.uncategorizedId.lowercased())' WHERE category_id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateAppsSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id.lowercased() as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        
        let deleteSQL = "DELETE FROM categories WHERE id = ?;"
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id.lowercased() as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func getAllCategories() -> [Category] {
        guard db != nil else { return [] }
        
        let sql = "SELECT * FROM categories ORDER BY sort_order, name;"
        
        return dbQueue.sync {
            var categories: [Category] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let category = extractCategory(from: statement!) {
                        categories.append(category)
                    }
                }
            }
            sqlite3_finalize(statement)
            return categories
        }
    }
    
    func getCategory(byId id: String) -> Category? {
        guard db != nil else { return nil }
        return dbQueue.sync { unsafeGetCategory(byId: id) }
    }
    
    private func unsafeGetCategory(byId id: String) -> Category? {
        guard db != nil else { return nil }
        
        var statement: OpaquePointer?
        var result: Category? = nil
        
        if sqlite3_prepare_v2(db, "SELECT * FROM categories WHERE id = ?;", -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id.lowercased() as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                result = extractCategory(from: statement!)
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    private func extractCategory(from statement: OpaquePointer) -> Category? {
        guard let idString = sqlite3_column_text(statement, 0),
              let nameString = sqlite3_column_text(statement, 1),
              let iconString = sqlite3_column_text(statement, 2),
              let colorString = sqlite3_column_text(statement, 3) else {
            return nil
        }
        
        let id = UUID(uuidString: String(cString: idString).lowercased())!
        let name = String(cString: nameString)
        let icon = String(cString: iconString)
        let color = String(cString: colorString)
        let order = Int(sqlite3_column_int(statement, 4))
        let isDefault = sqlite3_column_int(statement, 5) == 1
        
        return Category(id: id, name: name, icon: icon, color: color, order: order, isDefault: isDefault)
    }
    
    // MARK: - Application Operations
    
    /**
     Retrieves existing app or creates a new one.
     
     **Thread Safety:** Uses `dbQueue.sync` to ensure thread-safe access
     and return the created object.
     
     - Parameter name: Application name (e.g., "Safari")
     - Returns: The existing or newly created AppUsage
     */
    func getOrCreateApplication(name: String) -> AppUsage? {
        guard db != nil else { return nil }
        
        if let app = getApplication(name: name) {
            return app
        }
        
        let categoryId = guessCategoryId(for: name)
        
        let app = AppUsage(name: name, categoryId: categoryId)
        let sql = """
            INSERT INTO applications (id, name, category_id, first_seen, last_seen, total_time_spent, visit_count)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (app.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (app.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (app.categoryId as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 4, app.firstSeen.timeIntervalSince1970)
                sqlite3_bind_double(statement, 5, app.lastSeen.timeIntervalSince1970)
                sqlite3_bind_double(statement, 6, app.totalTimeSpent)
                sqlite3_bind_int(statement, 7, Int32(app.visitCount))
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    sqlite3_finalize(statement)
                    return app
                }
            }
            sqlite3_finalize(statement)
            return nil
        }
    }
    
    /**
     Intelligently guesses the category for a new app based on its name.
     
     Uses keyword matching to auto-categorize apps:
     - Development: xcode, terminal, github, cursor, vscode
     - Communication: slack, discord, teams, zoom
     - Entertainment: safari, chrome, netflix, spotify
     - etc.
     
     Falls back to "uncategorized" if no match found.
     */
    private func guessCategoryId(for appName: String) -> String {
        let name = appName.lowercased()
        let categories = getAllCategories()
        
        if name.contains("xcode") || name.contains("code") || name.contains("terminal") || 
           name.contains("github") || name.contains("cursor") || name.contains("sublime") ||
           name.contains("jetbrains") || name.contains("visual studio") {
            return categories.first { $0.name == "Development" }?.id.uuidString ?? Category.uncategorizedId
        }
        
        if name.contains("slack") || name.contains("discord") || name.contains("teams") || 
           name.contains("zoom") || name.contains("skype") || name.contains("telegram") ||
           name.contains("whatsapp") {
            return categories.first { $0.name == "Communication" }?.id.uuidString ?? Category.uncategorizedId
        }
        
        if name.contains("safari") || name.contains("chrome") || name.contains("firefox") || 
           name.contains("youtube") || name.contains("netflix") || name.contains("spotify") ||
           name.contains("steam") {
            return categories.first { $0.name == "Entertainment" }?.id.uuidString ?? Category.uncategorizedId
        }
        
        if name.contains("twitter") || name.contains("instagram") || name.contains("facebook") || 
           name.contains("messenger") || name.contains("tiktok") || name.contains("reddit") ||
           name.contains("linkedin") {
            return categories.first { $0.name == "Social" }?.id.uuidString ?? Category.uncategorizedId
        }
        
        if name.contains("notes") || name.contains("calendar") || name.contains("mail") || 
           name.contains("outlook") || name.contains("notion") || name.contains("todo") {
            return categories.first { $0.name == "Productivity" }?.id.uuidString ?? Category.uncategorizedId
        }
        
        if name.contains("excel") || name.contains("word") || name.contains("powerpoint") || 
           name.contains("keynote") || name.contains("numbers") || name.contains("pages") {
            return categories.first { $0.name == "Work" }?.id.uuidString ?? Category.uncategorizedId
        }
        
        return Category.uncategorizedId
    }
    
    func updateAppCategory(appId: String, categoryId: String) {
        let sql = "UPDATE applications SET category_id = ? WHERE id = ?;"
        
        dbQueue.sync { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (categoryId.lowercased() as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (appId as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getApplication(name: String) -> AppUsage? {
        guard db != nil else { return nil }
        
        let sql = "SELECT * FROM applications WHERE name = ?;"
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            var result: AppUsage? = nil
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = extractAppUsage(from: statement!)
                }
            }
            sqlite3_finalize(statement)
            return result
        }
    }
    
    /**
     Increments the visit count for an application.
     
     **Thread Safety:** Uses `dbQueue.async` as this is a fire-and-forget update.
     Called frequently when switching apps, so async prevents blocking UI.
     
     - Parameter name: Application name
     */
    func incrementAppVisits(name: String) {
        let sql = "UPDATE applications SET visit_count = visit_count + 1, last_seen = ? WHERE name = ?;"
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, (name as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getAllApplications() -> [AppUsage] {
        guard db != nil else { return [] }
        
        let sql = "SELECT * FROM applications ORDER BY total_time_spent DESC;"
        
        return dbQueue.sync {
            var apps: [AppUsage] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let app = extractAppUsage(from: statement!) {
                        apps.append(app)
                    }
                }
            }
            sqlite3_finalize(statement)
            return apps
        }
    }
    
    func getRecentApplications(limit: Int) -> [AppUsage] {
        guard db != nil else { return [] }
        
        let sql = "SELECT * FROM applications ORDER BY last_seen DESC LIMIT ?;"
        
        return dbQueue.sync {
            var apps: [AppUsage] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(limit))
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let app = extractAppUsage(from: statement!) {
                        apps.append(app)
                    }
                }
            }
            sqlite3_finalize(statement)
            return apps
        }
    }
    
    func getApplicationsByCategory(categoryId: String) -> [AppUsage] {
        guard db != nil else { return [] }
        
        let sql = "SELECT * FROM applications WHERE category_id = ? ORDER BY total_time_spent DESC;"
        
        return dbQueue.sync {
            var apps: [AppUsage] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (categoryId.lowercased() as NSString).utf8String, -1, nil)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let app = extractAppUsage(from: statement!) {
                        apps.append(app)
                    }
                }
            }
            sqlite3_finalize(statement)
            return apps
        }
    }
    
    func getCategoryStats() -> [(category: Category, time: TimeInterval, count: Int)] {
        let categories = getAllCategories()
        var stats: [(Category, TimeInterval, Int)] = []
        
        for category in categories {
            let apps = getApplicationsByCategory(categoryId: category.id.uuidString)
            let totalTime = apps.reduce(0) { $0 + $1.totalTimeSpent }
            stats.append((category, totalTime, apps.count))
        }
        
        return stats.sorted { $0.1 > $1.1 }
    }
    
    private func extractAppUsage(from statement: OpaquePointer) -> AppUsage? {
        guard let idString = sqlite3_column_text(statement, 0),
              let nameString = sqlite3_column_text(statement, 1) else {
            return nil
        }
        
        let id = UUID(uuidString: String(cString: idString))!
        let name = String(cString: nameString)
        let categoryId: String
        if let categoryIdText = sqlite3_column_text(statement, 2) {
            categoryId = String(cString: categoryIdText).lowercased()
        } else {
            categoryId = Category.uncategorizedId.lowercased()
        }
        let firstSeen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
        let lastSeen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
        let totalTimeSpent = sqlite3_column_double(statement, 5)
        let visitCount = Int(sqlite3_column_int(statement, 6))
        
        return AppUsage(
            id: id,
            name: name,
            categoryId: categoryId,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            totalTimeSpent: totalTimeSpent,
            visitCount: visitCount,
            windows: []
        )
    }
    
    // MARK: - Window Operations
    
    /**
     Retrieves existing window or creates a new one for the given app.
     
     **Thread Safety:** Uses `dbQueue.sync` to ensure thread-safe access
     and return the created object.
     
     - Parameters:
        - appId: Parent application UUID
        - title: Window title
     - Returns: The existing or newly created WindowUsage
     */
    func getOrCreateWindow(appId: String, title: String) -> WindowUsage? {
        guard db != nil else { return nil }
        
        if let window = getWindow(appId: appId, title: title) {
            return window
        }
        
        let window = WindowUsage(title: title)
        let sql = """
            INSERT INTO windows (id, app_id, title, first_seen, last_seen, total_time_spent, visit_count)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (window.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (appId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (title as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 4, window.firstSeen.timeIntervalSince1970)
                sqlite3_bind_double(statement, 5, window.lastSeen.timeIntervalSince1970)
                sqlite3_bind_double(statement, 6, window.totalTimeSpent)
                sqlite3_bind_int(statement, 7, Int32(window.visitCount))
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    sqlite3_finalize(statement)
                    return window
                }
            }
            sqlite3_finalize(statement)
            return nil
        }
    }
    
    func getWindow(appId: String, title: String) -> WindowUsage? {
        guard db != nil else { return nil }
        
        let sql = "SELECT * FROM windows WHERE app_id = ? AND title = ?;"
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            var result: WindowUsage? = nil
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (appId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (title as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = extractWindowUsage(from: statement!)
                }
            }
            sqlite3_finalize(statement)
            return result
        }
    }
    
    func getWindows(for appId: String) -> [WindowUsage] {
        guard db != nil else { return [] }
        
        let sql = "SELECT * FROM windows WHERE app_id = ? ORDER BY total_time_spent DESC;"
        
        return dbQueue.sync {
            var windows: [WindowUsage] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (appId as NSString).utf8String, -1, nil)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let window = extractWindowUsage(from: statement!) {
                        windows.append(window)
                    }
                }
            }
            sqlite3_finalize(statement)
            return windows
        }
    }
    
    private func extractWindowUsage(from statement: OpaquePointer) -> WindowUsage? {
        guard let idString = sqlite3_column_text(statement, 0),
              let titleString = sqlite3_column_text(statement, 2) else {
            return nil
        }
        
        let id = UUID(uuidString: String(cString: idString))!
        let title = String(cString: titleString)
        let firstSeen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
        let lastSeen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
        let totalTimeSpent = sqlite3_column_double(statement, 5)
        let visitCount = Int(sqlite3_column_int(statement, 6))
        
        return WindowUsage(
            id: id,
            title: title,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            totalTimeSpent: totalTimeSpent,
            visitCount: visitCount,
            sessions: []
        )
    }
    
    // MARK: - Session Operations
    
    /**
     Creates a new usage session in the database.
     
     **Thread Safety:** Uses `dbQueue.sync` to ensure thread-safe insertion
     and return the session object with its generated UUID.
     
     - Parameter windowId: The window this session belongs to
     - Returns: Newly created session or nil on failure
     */
    func createSession(windowId: String) -> UsageSession? {
        let session = UsageSession()
        let sql = """
            INSERT INTO sessions (id, window_id, start_time, end_time, duration)
            VALUES (?, ?, ?, NULL, 0);
        """
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (session.id.uuidString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (windowId as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 3, session.startTime.timeIntervalSince1970)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    sqlite3_finalize(statement)
                    return session
                }
            }
            sqlite3_finalize(statement)
            return nil
        }
    }
    
    /**
     Ends a session by setting its end time and calculating duration.
     
     **Thread Safety:** Uses `dbQueue.async` as this is a fire-and-forget update.
     Called on every app/window switch, so async prevents blocking UI.
     
     - Parameter id: Session UUID
     */
    func endSession(id: String) {
        let endTime = Date()
        let sql = """
            UPDATE sessions
            SET end_time = ?, duration = ? - (SELECT start_time FROM sessions WHERE id = ?)
            WHERE id = ?;
        """
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, endTime.timeIntervalSince1970)
                sqlite3_bind_double(statement, 2, endTime.timeIntervalSince1970)
                sqlite3_bind_text(statement, 3, (id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (id as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    /**
     Adds time to a window's total time spent.
     
     **Thread Safety:** Uses `dbQueue.async` as this is a fire-and-forget update.
     Called on every session end, so async prevents blocking UI.
     
     - Parameters:
        - id: Window UUID
        - duration: Time to add (in seconds)
     */
    func updateWindowTime(id: String, duration: TimeInterval) {
        let sql = "UPDATE windows SET total_time_spent = total_time_spent + ? WHERE id = ?;"
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, duration)
                sqlite3_bind_text(statement, 2, (id as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    /**
     Adds time to an application's total time spent.
     
     **Thread Safety:** Uses `dbQueue.async` as this is a fire-and-forget update.
     Called on every session end, so async prevents blocking UI.
     
     - Parameters:
        - id: Application UUID
        - duration: Time to add (in seconds)
     */
    func updateAppTime(id: String, duration: TimeInterval) {
        let sql = "UPDATE applications SET total_time_spent = total_time_spent + ? WHERE id = ?;"
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, duration)
                sqlite3_bind_text(statement, 2, (id as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    /**
     Increments the visit count for a window.
     
     **Thread Safety:** Uses `dbQueue.async` as this is a fire-and-forget update.
     Called when switching to an existing window, so async prevents blocking UI.
     
     - Parameter id: Window UUID
     */
    func incrementWindowVisits(id: String) {
        let sql = "UPDATE windows SET visit_count = visit_count + 1, last_seen = ? WHERE id = ?;"
        
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, (id as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getTodayTime(for appId: String) -> TimeInterval {
        guard db != nil else { return 0 }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let sql = """
            SELECT SUM(duration) FROM sessions
            JOIN windows ON sessions.window_id = windows.id
            WHERE windows.app_id = ? AND sessions.start_time >= ?;
        """
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            var totalTime: TimeInterval = 0
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (appId as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 2, startOfDay.timeIntervalSince1970)
                if sqlite3_step(statement) == SQLITE_ROW {
                    totalTime = sqlite3_column_double(statement, 0)
                }
            }
            sqlite3_finalize(statement)
            return totalTime
        }
    }
    
    func getTime(for date: Date) -> TimeInterval {
        guard db != nil else { return 0 }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let sql = """
            SELECT SUM(duration) FROM sessions
            WHERE start_time >= ? AND start_time < ?;
        """
        
        return dbQueue.sync {
            var statement: OpaquePointer?
            var totalTime: TimeInterval = 0
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, startOfDay.timeIntervalSince1970)
                sqlite3_bind_double(statement, 2, endOfDay.timeIntervalSince1970)
                if sqlite3_step(statement) == SQLITE_ROW {
                    totalTime = sqlite3_column_double(statement, 0)
                }
            }
            sqlite3_finalize(statement)
            return totalTime
        }
    }
    
    func getCategoryTotalsForWeek(startingFrom weekStart: Date) -> [(category: Category, time: TimeInterval)] {
        guard db != nil else { return [] }
        
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfDay(for: weekStart)
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        print("📊 Category query: start=\(startOfWeek), end=\(endOfWeek)")
        
        let sql = """
            SELECT COALESCE(a.category_id, '\(Category.uncategorizedId.lowercased())') as category_id, SUM(s.duration) as total_time
            FROM sessions s
            JOIN windows w ON s.window_id = w.id
            JOIN applications a ON w.app_id = a.id
            WHERE s.start_time >= ? AND s.start_time < ?
            GROUP BY category_id
            ORDER BY total_time DESC;
        """
        
        return dbQueue.sync {
            var results: [(Category, TimeInterval)] = []
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, startOfWeek.timeIntervalSince1970)
                sqlite3_bind_double(statement, 2, endOfWeek.timeIntervalSince1970)
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let categoryIdCString = sqlite3_column_text(statement, 0) {
                        let categoryId = String(cString: categoryIdCString).lowercased()
                        let totalTime = sqlite3_column_double(statement, 1)
                        
                        print("📊 Found category_id=\(categoryId), time=\(totalTime)")
                        
                        if let category = unsafeGetCategory(byId: categoryId) {
                            results.append((category, totalTime))
                        } else {
                            print("📊 Category not found for id=\(categoryId), using uncategorized")
                            if let uncategorized = unsafeGetCategory(byId: Category.uncategorizedId) {
                                results.append((uncategorized, totalTime))
                            }
                        }
                    }
                }
            } else {
                print("📊 SQL prepare failed")
            }
            sqlite3_finalize(statement)
            print("📊 Total results: \(results.count)")
            return results
        }
    }
}

// MARK: - Extensions

extension AppUsage {
    func formattedTotalTime() -> String {
        return totalTimeSpent.formatted()
    }
}

extension WindowUsage {
    func formattedTotalTime() -> String {
        return totalTimeSpent.formatted()
    }
}

/**
 Time formatting utilities for TimeInterval.
 
 Provides human-readable formatting for time durations:
 - Short format: "5m 30s", "2h 15m"
 - Detailed format: "2h 05m 30s" (with leading zeros)
 */
extension TimeInterval {
    /**
     Formats time in short human-readable format.
     
     Examples:
     - 45 seconds → "45s"
     - 5 minutes 30 seconds → "5m 30s"
     - 2 hours 15 minutes → "2h 15m"
     */
    func formatted() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /**
     Formats time in detailed format with leading zeros.
     
     Examples:
     - 45 seconds → "45s"
     - 5 minutes 30 seconds → "5m 30s"
     - 2 hours 15 minutes 5 seconds → "2h 05m 05s"
     */
    func formattedDetailed() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    /// Formats time in short format without seconds (e.g., "2h 15m" or "45m")
    var formattedShort: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Formats time as decimal hours (e.g., "2.5h")
    var formattedHours: String {
        let hours = Double(self) / 3600.0
        return String(format: "%.1fh", hours)
    }
}

/**
 Color extension for creating SwiftUI Colors from hex strings.
 
 Supports:
 - 3-digit RGB (e.g., "#F0A")
 - 6-digit RGB (e.g., "#FF00AA")
 - 8-digit ARGB (e.g., "#80FF00AA")
 */
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
