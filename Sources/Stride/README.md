# Feature: /Users/orlandoascanio/Desktop/screen-detector/Sources/Stride

## 1. Purpose

**What this feature does:**
- Serves as the root module for the Stride macOS application
- Provides the `@main` entry point via `StrideApp.swift`
- Orchestrates all sub-modules: `Core/`, `Models/`, `Views/`
- Contains the central `AppState` coordinator for real-time data flow
- Manages `UsageDatabase` for app/window/session tracking (in `Models.swift`)

**What problem it solves:**
- **System Integration**: Bridges macOS Accessibility APIs with SwiftUI presentation
- **State Coordination**: Single source of truth via `AppState` for UI bindings
- **Passive Tracking**: Background monitoring without user intervention
- **Multi-Window Focus**: Tracks granular window titles, not just app names

**What it explicitly does NOT handle:**
- Habit persistence (belongs in `Core/HabitDatabase.swift`)
- Weekly log persistence (belongs in `Core/WeeklyLogDatabase.swift`)
- View rendering details (belongs in `Views/` subfolders)
- Model definitions for habits/weekly logs (belongs in `Models/`)

## 2. Scope Boundaries

**Belongs inside this feature (root level):**
- Application entry point (`StrideApp.swift`)
- Global state coordinator (`AppState` in `StrideApp.swift`)
- Usage tracking models and database (`Models.swift`)
- Root content view (`ContentView.swift`)
- Sub-module folders: `Core/`, `Models/`, `Views/`

**Must NEVER be added here:**
- View-specific components (belongs in `Views/`)
- Habit/WeeklyLog model definitions (belongs in `Models/`)
- Database managers for habits/weekly logs (belongs in `Core/`)

**Module dependency graph:**
```
StrideApp.swift
    ├── imports SwiftUI, AppKit
    ├── imports Models.swift (UsageDatabase)
    └── imports Core/AppMonitor, Core/SessionManager

Models.swift
    ├── imports Foundation, SQLite3, SwiftUI
    └── standalone (no internal dependencies)

Core/
    ├── imports Foundation, SQLite3, AppKit
    └── imports Models/ (for Habit, WeeklyLogEntry types)

Models/
    ├── imports Foundation only
    └── standalone (no internal dependencies)

Views/
    ├── imports SwiftUI
    ├── imports Models.swift (for types)
    ├── imports Core/ (for databases)
    └── imports parent (for AppState)
```

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     StrideApp.swift (@main)                      │
│  - WindowGroup with MainWindowView                               │
│  - MenuBarExtra for quick status                                 │
│  - AppDelegate for lifecycle events                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ environmentObject(AppState.shared)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AppState                                  │
│  Published: activeAppName, activeWindowTitle, elapsedTime,      │
│             recentApps, currentCategoryColor, formattedTime     │
│                                                                 │
│  Services: appMonitor: AppMonitor, sessionManager: SessionManager│
│  Delegate: implements AppMonitorDelegate                         │
└─────────────────────────────────────────────────────────────────┘
         │                           │                           │
         │ uses                      │ persists to               │ notifies
         ▼                           ▼                           ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────────────┐
│   AppMonitor    │     │ SessionManager  │     │     UsageDatabase       │
│   (Core/)       │     │   (Core/)       │     │     (Models.swift)      │
└─────────────────┘     └─────────────────┘     └─────────────────────────┘
         │                       │                           │
         │                       │                           │
         ▼                       ▼                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Views/                                  │
│  MainWindowView → Sidebar + Detail (Today, Apps, Categories,   │
│  Trends, Habits, WeeklyLog, CurrentSession)                     │
└─────────────────────────────────────────────────────────────────┘
```

**Data Flow:**
1. `NSWorkspace` fires `didActivateApplicationNotification`
2. `AppMonitor` receives notification → calls `delegate?.appMonitor(_:didDetectAppChange:)`
3. `AppState` (delegate) receives callback → calls `SessionManager.endCurrentSession()` then `startNewSession()`
4. `SessionManager` writes to `UsageDatabase.shared` (async)
5. `AppState` updates `@Published` properties → SwiftUI views re-render

## 4. Folder Structure Explanation

### `StrideApp.swift`
**What it does:** Application entry point and global state coordinator.

**Key components:**
- `StrideApp` - `@main` struct with `WindowGroup` and `MenuBarExtra`
- `AppDelegate` - Handles `applicationDidFinishLaunching`
- `AppState` - `ObservableObject` coordinating all runtime state

**Who calls it:** macOS runtime (via `@main`)

**What calls it:** SwiftUI framework for scene management

**Side effects:**
- Starts `AppMonitor` on init
- Creates `UsageDatabase.shared` singleton on first access
- Writes to database on every app/window switch

**Critical assumptions:**
- `AppState.shared` singleton lives for entire app lifetime
- Accessibility permissions granted by user

### `Models.swift`
**What it does:** Defines usage tracking models and `UsageDatabase` manager.

**Key types:**
- `Category` - User-defined app categories (Work, Entertainment, etc.)
- `AppCategory` - Legacy enum for migration compatibility
- `AppUsage` - Aggregate usage for an application
- `WindowUsage` - Aggregate usage for a specific window
- `UsageSession` - Single continuous usage session
- `UsageDatabase` - Thread-safe SQLite manager for usage data

**Database schema:**
- `categories` - Category definitions
- `applications` - App usage aggregates
- `windows` - Window usage aggregates
- `sessions` - Individual time sessions

**Who calls it:** `AppState`, `SessionManager`, all Views displaying usage data

**Side effects:**
- Creates `~/Library/Application Support/Stride/usage.db` on first run
- Auto-categorizes new apps based on name heuristics
- Initializes 8 default categories on first run

### `ContentView.swift`
**What it does:** Root view (currently minimal, main content in `Views/MainWindow/`)

**Who calls it:** Not actively used (legacy/placeholder)

### `Core/` folder
**Contains:** Monitoring, session management, and database infrastructure

**Files:**
- `AppMonitor.swift` - NSWorkspace event handling + window polling
- `WindowTitleProvider.swift` - Accessibility API wrapper
- `SessionManager.swift` - Session lifecycle management
- `HabitDatabase.swift` - Habit persistence (refactored to use BaseDatabase)
- `WeeklyLogDatabase.swift` - Weekly log persistence (refactored to use BaseDatabase)
- `BaseDatabase.swift` - Shared SQLite infrastructure

**See:** `Core/README.md` for detailed documentation

### `Models/` folder
**Contains:** Pure value type definitions for habits and weekly logs

**Files:**
- `HabitModels.swift` - `Habit`, `HabitEntry`, `HabitStreak`, `HabitStatistics`
- `WeeklyLogModels.swift` - `WeeklyLogEntry`, `WeekInfo`, Date extensions

**See:** `Models/README.md` for detailed documentation

### `Views/` folder
**Contains:** All SwiftUI views and view models

**Subfolders:**
- `MainWindow/` - Main window layout
- `MenuBar/` - Menu bar dropdown
- `CurrentSession/` - Live session display
- `Today/` - Today's usage summary
- `Apps/` - App listing and details
- `Categories/` - Category management
- `Trends/` - Weekly trends
- `HabitTracker/` - Habit tracking UI
- `WeeklyLog/` - Weekly log UI
- `Shared/` - Reusable components

**See:** `Views/README.md` for detailed documentation

## 5. Public API

### AppState

```swift
class AppState: ObservableObject {
    static let shared: AppState
    
    // Published Properties (UI bindings)
    @Published var activeAppName: String
    @Published var activeWindowTitle: String
    @Published var elapsedTime: TimeInterval
    @Published var formattedTime: String
    @Published var recentApps: [AppUsage]
    @Published var currentCategoryColor: Color
    
    // Computed Statistics
    var totalVisitsToday: Int { get }
    var totalTimeToday: TimeInterval { get }
    
    // Methods
    func refreshRecentApps()
}

// AppMonitorDelegate implementation
extension AppState: AppMonitorDelegate {
    func appMonitor(_ monitor: AppMonitor, didDetectAppChange app: NSRunningApplication)
    func appMonitor(_ monitor: AppMonitor, didDetectWindowChange title: String)
    func appMonitorDidUpdateElapsedTime(_ monitor: AppMonitor)
}
```

### UsageDatabase

```swift
class UsageDatabase {
    static let shared: UsageDatabase
    
    // Category Operations
    func createCategory(_ category: Category)
    func updateCategory(_ category: Category)
    func deleteCategory(id: String)
    func getAllCategories() -> [Category]
    func getCategory(byId id: String) -> Category?
    
    // Application Operations
    func getOrCreateApplication(name: String) -> AppUsage?
    func getApplication(name: String) -> AppUsage?
    func getAllApplications() -> [AppUsage]
    func getRecentApplications(limit: Int) -> [AppUsage]
    func getApplicationsByCategory(categoryId: String) -> [AppUsage]
    func updateAppCategory(appId: String, categoryId: String)
    func incrementAppVisits(name: String)
    
    // Window Operations
    func getOrCreateWindow(appId: String, title: String) -> WindowUsage?
    func getWindow(appId: String, title: String) -> WindowUsage?
    func getWindows(for appId: String) -> [WindowUsage]
    func incrementWindowVisits(id: String)
    
    // Session Operations
    func createSession(windowId: String) -> UsageSession?
    func endSession(id: String)
    func updateWindowTime(id: String, duration: TimeInterval)
    func updateAppTime(id: String, duration: TimeInterval)
    
    // Statistics
    func getTodayTime(for appId: String) -> TimeInterval
    func getTime(for date: Date) -> TimeInterval
    func getCategoryStats() -> [(category: Category, time: TimeInterval, count: Int)]
    func getCategoryTotalsForWeek(startingFrom date: Date) -> [(category: String, time: TimeInterval)]
}
```

### Model Types (Models.swift)

```swift
struct Category: Codable, Identifiable, Hashable {
    static let uncategorizedId: String
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var order: Int
    var isDefault: Bool
    
    static let defaultCategories: [Category]
}

struct AppUsage: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var categoryId: String
    var firstSeen: Date
    var lastSeen: Date
    var totalTimeSpent: TimeInterval
    var visitCount: Int
    var windows: [WindowUsage]
    
    func getCategory() -> Category
}

struct WindowUsage: Codable, Identifiable {
    let id: UUID
    var title: String
    var firstSeen: Date
    var lastSeen: Date
    var totalTimeSpent: TimeInterval
    var visitCount: Int
    var sessions: [UsageSession]
}

struct UsageSession: Codable, Identifiable {
    let id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    
    mutating func end()
}
```

## 6. Internal Logic Details

### AppState Session Lifecycle

```
User switches apps:
├── NSWorkspace.didActivateApplicationNotification fires
├── AppMonitor.appDidActivate() called
├── AppMonitor calls delegate?.appMonitor(_:didDetectAppChange:)
├── AppState.appMonitor(_:didDetectAppChange:) called
│   ├── sessionManager.endCurrentSession() [persists previous session]
│   ├── sessionManager.startNewSession(appName:windowTitle:)
│   ├── Update @Published properties
│   ├── Look up category color → update currentCategoryColor
│   ├── Reset appStartTime, elapsedTime
│   └── refreshRecentApps()
└── SwiftUI views re-render with new state
```

### UsageDatabase Auto-Categorization

```swift
// Apps are auto-categorized on creation based on name heuristics:
guessCategoryId(for appName: String) -> String {
    // Development: xcode, terminal, github, cursor, vscode
    // Communication: slack, discord, teams, zoom
    // Entertainment: safari, chrome, netflix, spotify
    // Social: twitter, instagram, facebook
    // Productivity: notes, calendar, mail, notion
    // Work: excel, word, powerpoint
    // Default: Uncategorized
}
```

### Thread Safety Pattern (UsageDatabase)

```swift
// Same pattern as Core databases
private let dbQueue = DispatchQueue(label: "com.stride.database", qos: .utility)

// Reads: sync (caller waits)
func getAllApplications() -> [AppUsage] {
    return dbQueue.sync { /* SQL operations */ }
}

// Writes: async (fire-and-forget)
func updateAppTime(id: String, duration: TimeInterval) {
    dbQueue.async { /* SQL operations */ }
}
```

## 7. Data Contracts

### UsageDatabase Schema

```sql
-- categories table
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    icon TEXT NOT NULL DEFAULT 'folder',
    color TEXT NOT NULL DEFAULT '#7F8C8D',
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_default INTEGER NOT NULL DEFAULT 0
);

-- applications table
CREATE TABLE applications (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    category_id TEXT DEFAULT 'uncategorized',
    first_seen REAL NOT NULL,
    last_seen REAL NOT NULL,
    total_time_spent REAL NOT NULL DEFAULT 0,
    visit_count INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET DEFAULT
);

-- windows table
CREATE TABLE windows (
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

-- sessions table
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    window_id TEXT NOT NULL,
    start_time REAL NOT NULL,
    end_time REAL,
    duration REAL NOT NULL DEFAULT 0,
    FOREIGN KEY (window_id) REFERENCES windows(id) ON DELETE CASCADE
);
```

**Breaking-change risk areas:**
- Changing `category_id` format breaks foreign key relationships
- Adding columns requires migration (currently manual PRAGMA-based)
- `total_time_spent` and `duration` in seconds (not milliseconds)

## 8. Failure Modes

**Known failure cases:**
- Accessibility permission not granted → empty window titles
- App terminated mid-session → session time lost (not persisted)
- Database corrupted → `sqlite3_open` fails, all operations become no-ops

**Silent failure risks:**
- Auto-categorization may misclassify apps silently
- `endSession()` called on non-existent session is a no-op
- `getCategory(byId:)` returns nil for invalid IDs

**Race conditions:**
- Rapid app switching may cause overlapping `startNewSession()` calls
- `UsageDatabase` async writes may complete after new session starts

**Memory issues:**
- `AppState` singleton never deallocated (by design)
- `recentApps` array grows unbounded (limit: 5)

**Performance bottlenecks:**
- `getAllApplications()` loads all apps into memory
- `getTodayTime()` joins sessions + windows tables on every call
- No caching of category lookups

## 9. Observability

**Logs produced:**
- `"Failed to initialize database - operations will be no-ops"`
- `"Error opening database at path: <path>"`
- `"SQL Error: <message>"`
- `"Notification permissions: Feature disabled in SPM build"`

**Debug strategy:**
- Check `~/Library/Application Support/Stride/usage.db` with sqlite3 CLI
- Monitor Console.app for "SQL Error" messages
- Add prints to `startSession()` for session tracking
- Use SQLite Browser to inspect data integrity

**How to test locally:**
```swift
// Test UsageDatabase
let db = UsageDatabase.shared
let app = db.getOrCreateApplication(name: "TestApp")
db.incrementAppVisits(name: "TestApp")
let apps = db.getAllApplications()
print("Total apps: \(apps.count)")

// Test AppState (requires running app)
let state = AppState.shared
print("Active app: \(state.activeAppName)")
print("Elapsed: \(state.formattedTime)")
```

## 10. AI Agent Instructions

**How to modify this feature:**
1. Read `StrideApp.swift` for state coordination patterns
2. Read `Models.swift` for UsageDatabase schema and operations
3. Understand the delegate pattern: `AppMonitor` → `AppState` → `SessionManager`

**Files that must be read before editing:**
- `StrideApp.swift` - understand AppState lifecycle
- `Models.swift` - understand UsageDatabase schema
- `Core/AppMonitor.swift` - understand monitoring events
- `Core/SessionManager.swift` - understand session lifecycle

**Safe refactoring rules:**
- Adding new `@Published` properties to `AppState` is safe
- Adding new query methods to `UsageDatabase` follows existing patterns
- Adding new categories to `Category.defaultCategories` is safe (append only)
- Views can safely observe `AppState.shared`

**Forbidden modifications:**
- DO NOT change `AppState.shared` singleton pattern
- DO NOT call `SessionManager` directly from Views (go through AppState)
- DO NOT bypass `dbQueue` in `UsageDatabase` (thread safety violation)
- DO NOT change default category UUIDs (breaks database foreign keys)

## 11. Extension Points

**Safe addition locations:**
- New `@Published` properties in `AppState` for UI state
- New query methods in `UsageDatabase` for statistics
- New computed properties on `AppUsage`/`WindowUsage`
- New subfolders in `Views/` for new features

**How to extend:**
```swift
// Adding new AppState property
class AppState: ObservableObject {
    @Published var newFeatureState: Bool = false
    
    func toggleNewFeature() {
        newFeatureState.toggle()
    }
}

// Adding new UsageDatabase query
extension UsageDatabase {
    func getSessionsForApp(appId: String, from: Date, to: Date) -> [UsageSession] {
        // New query implementation
    }
}

// Adding new category
extension Category {
    static let defaultCategories: [Category] = [
        // ... existing ...
        Category(id: UUID(), name: "Gaming", icon: "gamecontroller.fill", color: "#9B59B6", order: 7, isDefault: true)
    ]
}
```

## 12. Technical Debt & TODO

**Weak areas:**
- No migration versioning system in `UsageDatabase` (unlike Core databases)
- Silent no-ops on database failures
- No error propagation to UI layer
- Duplicate Date extensions in `Models/` and legacy code

**Refactor targets:**
- Migrate `UsageDatabase` to use `BaseDatabase` infrastructure
- Add `Result<T, DatabaseError>` return types
- Extract auto-categorization heuristics to configurable rules
- Consolidate Date extensions into single file

**Simplification ideas:**
- Replace manual SQL with lightweight query builder
- Use Combine publishers for database changes
- Add repository layer between Views and Database

**Missing:**
- Database backup/export functionality
- Cloud sync capability
- Unit tests for auto-categorization
- Comprehensive error handling in AppState
