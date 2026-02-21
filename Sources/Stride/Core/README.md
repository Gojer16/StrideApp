# Feature: /Users/orlandoascanio/Desktop/screen-detector/Sources/Stride/Core

## 1. Purpose

**What this feature does:**
- Monitors macOS application and window focus changes via `NSWorkspace` notifications
- Retrieves active window titles via macOS Accessibility APIs (`AXUIElement`)
- Manages time-tracking session lifecycle for app usage statistics
- Provides thread-safe SQLite persistence for habits (`habits.db`) and weekly logs (`weeklylog.db`)

**What problem it solves:**
- macOS does not emit window-change notifications for third-party apps; this module implements a hybrid polling/event-driven strategy
- Raw SQLite provides predictable performance vs. CoreData for high-frequency session writes
- Serial dispatch queues prevent `SQLITE_BUSY` errors and race conditions

**What it explicitly does NOT handle:**
- UI rendering (belongs in `Sources/Stride/Views/`)
- Global application state (belongs in `Sources/Stride/StrideApp.swift` or `AppState`)
- Usage tracking database (`UsageDatabase` lives in `Sources/Stride/Models.swift`)
- Model definitions (belong in `Sources/Stride/Models/`)

## 2. Scope Boundaries

**Belongs inside this feature:**
- System-level monitoring classes (`AppMonitor`, `WindowTitleProvider`)
- Session orchestration logic (`SessionManager`)
- SQLite database managers for habits and weekly logs (`HabitDatabase`, `WeeklyLogDatabase`)
- Thread-safety dispatch queues for database operations

**Must NEVER be added here:**
- SwiftUI views or UI components
- Business model structs (`Habit`, `HabitEntry`, `WeeklyLogEntry` - define in `Models/`)
- The `UsageDatabase` class (lives in `Models.swift`)
- Navigation or routing logic

**Dependencies on other features:**
- `Sources/Stride/Models.swift`: Provides `UsageDatabase`, `AppUsage`, `WindowUsage`, `UsageSession`
- `Sources/Stride/Models/HabitModels.swift`: Provides `Habit`, `HabitEntry`, `HabitStreak`, `HabitStatistics`
- `Sources/Stride/Models/WeeklyLogModels.swift`: Provides `WeeklyLogEntry`, `WeekInfo`

**Ownership boundaries:**
- `AppMonitor`: Owns `WindowTitleProvider` instance
- `SessionManager`: Depends on `UsageDatabase.shared` singleton (external)
- `HabitDatabase`: Owns its SQLite connection and `dbQueue`
- `WeeklyLogDatabase`: Owns its SQLite connection and `dbQueue`

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        External System                           │
│  NSWorkspace.didActivateApplicationNotification                  │
│  AXUIElement (Accessibility API)                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       AppMonitor                                 │
│  - Event-driven app change detection (instant)                   │
│  - Timer-based window polling (2s interval)                      │
│  - Delegate pattern: AppMonitorDelegate                          │
│  - Calls WindowTitleProvider.getWindowTitle(for:) internally     │
└─────────────────────────────────────────────────────────────────┘
         │                                       │
         │ app change                            │ window change (via delegate)
         ▼                                       ▼
┌────────────────────────────────┐    ┌────────────────────────────┐
│      SessionManager            │    │    WindowTitleProvider     │
│ - startNewSession()            │    │ - getWindowTitle(for:)     │
│ - endCurrentSession()          │    │ - AXUIElement queries      │
│ - Tracks current session state │    │ - Pure query (no callbacks)│
└────────────────────────────────┘    └────────────────────────────┘
         │
         │ persists to
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    UsageDatabase (external)                      │
│                    File: Sources/Stride/Models.swift             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     Separate Persistence Layers                  │
├─────────────────────────────┬───────────────────────────────────┤
│      HabitDatabase          │      WeeklyLogDatabase            │
│  File: habits.db            │  File: weeklylog.db               │
│  Queue: com.stride.habits   │  Queue: com.stride.weeklylog      │
└─────────────────────────────┴───────────────────────────────────┘
```

**Entry points:**
- `AppMonitor.startMonitoring()` - begins system monitoring
- `SessionManager.startNewSession(appName:windowTitle:)` - begins a tracking session
- `HabitDatabase.shared` - singleton access for habit persistence
- `WeeklyLogDatabase.shared` - singleton access for weekly log persistence

**Coordination layer (not shown in diagram):**
- `AppState` (in `Sources/Stride/StrideApp.swift`) implements `AppMonitorDelegate`
- `AppState` receives delegate callbacks and manually orchestrates calls to `SessionManager.startNewSession()` and `endCurrentSession()`
- `SessionManager` does NOT implement `AppMonitorDelegate` directly; it is controlled by `AppState`

**State management strategy:**
- `AppMonitor`: Holds `currentApp` (NSRunningApplication?) and `lastWindowTitle` (String); both are publicly read-only (`private(set)`)
- `SessionManager`: Holds `currentSession`, `currentApp`, `currentWindow`; all are publicly read-only (`private(set)`), internally mutable
- Database classes: Stateless singletons; state is persisted to SQLite

**Why three separate database files:**
- `usage.db`: App/window/session usage tracking (managed by `UsageDatabase` in Models.swift)
- `habits.db`: Habit definitions and entries (managed by `HabitDatabase`)
- `weeklylog.db`: Manual weekly log entries (managed by `WeeklyLogDatabase`)
- Rationale: Each feature has independent data lifecycle; habits/weekly logs can be cleared without affecting usage history

**Graceful shutdown behavior:**
- On app termination, active session time is LOST if `endCurrentSession()` is not called
- Databases close via `deinit` with `sqlite3_close(db)`; in-flight async writes may be lost
- App should call `AppMonitor.stopMonitoring()` and `SessionManager.endCurrentSession()` in `applicationWillTerminate`

**1-second elapsed timer purpose:**
- Fires `appMonitorDidUpdateElapsedTime()` to notify delegate every second
- Consumed by `AppState` to update UI showing "time spent in current app" display
- Not persisted; only for real-time UI feedback

**Data flow:**
1. User switches app → `NSWorkspace` fires notification → `AppMonitor.appDidActivate()`
2. `AppMonitor` calls `delegate?.appMonitor(_:didDetectAppChange:)` 
3. Delegate (typically AppState) calls `SessionManager.endCurrentSession()` then `startNewSession()`
4. `SessionManager` writes to `UsageDatabase.shared` (async)

## 4. Folder Structure Explanation

### `AppMonitor.swift`
**What it does:** Monitors app switches and window title changes using hybrid strategy.

**Why it exists:** macOS provides app-switch notifications but NOT window-change events within the same app.

**Who calls it:** Typically instantiated and controlled by `AppState` in `StrideApp.swift`.

**What calls it:** 
- `NSWorkspace.shared.notificationCenter` (app activation)
- Internal timers (window polling every 2s, elapsed time every 1s)

**Side effects:**
- Modifies `currentApp` and `lastWindowTitle` state
- Fires delegate callbacks on every app/window change
- CPU usage from Accessibility API polling

**Critical assumptions:**
- Delegate implements `AppMonitorDelegate` protocol
- Called from main thread (Accessibility API requirement)

### `WindowTitleProvider.swift`
**What it does:** Retrieves the frontmost window title using Accessibility APIs.

**Why it exists:** Encapsulates all `AXUIElement` complexity and error handling.

**Who calls it:** `AppMonitor.checkWindowTitleChange()` calls `getWindowTitle(for:)`.

**What calls it:** Accessibility framework (system-level).

**Side effects:** None (pure query).

**Critical assumptions:**
- User has granted Accessibility permissions in System Settings
- Called from main thread
- Target app supports Accessibility (sandboxed apps may not)

### `SessionManager.swift`
**What it does:** Orchestrates the lifecycle of usage tracking sessions.

**Why it exists:** Separates session logic from monitoring concerns.

**Who calls it:** `AppState` (via `AppMonitorDelegate` callbacks).

**What calls it:** None (no system callbacks).

**Side effects:**
- Writes to `UsageDatabase.shared` on every session end
- Updates visit counts in database

**Critical assumptions:**
- `endCurrentSession()` MUST be called BEFORE `startNewSession()` to avoid data loss. If `startNewSession()` is called without first calling `endCurrentSession()`, the in-progress session's elapsed time will NOT be persisted to the database.
- Single-threaded access required (typically main thread). Concurrent calls to `startNewSession()` from multiple threads may cause session state corruption and orphaned database records.

### `HabitDatabase.swift`
**What it does:** Thread-safe SQLite persistence for habit tracking.

**Why it exists:** Stores `habits` and `habit_entries` tables with streak calculations.

**Who calls it:** Views in `Sources/Stride/Views/` (Habits feature).

**What calls it:** SQLite C library.

**Side effects:**
- Creates `~/Library/Application Support/Stride/habits.db` on first run
- Inserts sample habits if database is empty
- Updates `@Published var lastUpdate` on changes (triggers SwiftUI refresh)

**Critical assumptions:**
- All public methods are thread-safe via `dbQueue`
- UUID strings are valid (forced unwrap in `extractEntry`)

**Lifecycle contract:**
- Singleton initialized on first access to `.shared`
- `sqlite3_close(db)` called in `deinit` (typically never during app lifetime)
- In-flight `dbQueue.async` writes may be lost on sudden app termination

### `WeeklyLogDatabase.swift`
**What it does:** Thread-safe SQLite persistence for weekly log entries.

**Why it exists:** Stores `weekly_log_entries` and `weekly_log_category_colors` tables.

**Who calls it:** Views in `Sources/Stride/Views/` (Weekly Log feature).

**What calls it:** SQLite C library.

**Side effects:**
- Creates `~/Library/Application Support/Stride/weeklylog.db` on first run
- Auto-assigns random colors to new categories
- Inserts sample data if database is empty

**Critical assumptions:**
- Explicit column list (`entryColumns`) ensures index stability after migrations
- Date ranges use Unix timestamp (seconds since 1970)

## 5. Public API

### `AppMonitor`
```swift
weak var delegate: AppMonitorDelegate?
var currentApp: NSRunningApplication? { get }

func startMonitoring()
func stopMonitoring()
func getCurrentWindowTitle() -> String
```

**Input types:**
- `delegate`: Any object implementing `AppMonitorDelegate`
- No inputs to `startMonitoring()` / `stopMonitoring()`

**Output types:**
- `currentApp`: `NSRunningApplication?` (nil if no app focused)
- `getCurrentWindowTitle()`: `String` (empty string if unavailable)

**Error behavior:** Silent failures - returns empty strings, does not throw.

**Edge cases:**
- App with no focused window returns empty title
- Sandbox-restricted apps may return empty title
- Calling `startMonitoring()` twice without calling `stopMonitoring()` first registers duplicate notification observers and creates overlapping timers. Both will fire, causing duplicate delegate callbacks and increased CPU usage.

**Idempotency:** `stopMonitoring()` is safe to call multiple times.

### `AppMonitorDelegate`
```swift
func appMonitor(_ monitor: AppMonitor, didDetectAppChange app: NSRunningApplication)
func appMonitor(_ monitor: AppMonitor, didDetectWindowChange title: String)
func appMonitorDidUpdateElapsedTime(_ monitor: AppMonitor)
```

### `WindowTitleProvider`
```swift
func getWindowTitle(for app: NSRunningApplication) -> String
```
**Returns:** Window title or empty string if unavailable.

**Contract clarifications:**
- Returns `""` (empty string) on any failure; `String?` was rejected to simplify call sites
- If `app` process has terminated, returns `""` (does not crash)
- Thread-unsafe: must be called from main thread (Accessibility API requirement)

### `SessionManager`
```swift
var currentSession: UsageSession? { get }
var currentApp: AppUsage? { get }
var currentWindow: WindowUsage? { get }
var hasActiveSession: Bool { get }
var currentSessionStartTime: Date? { get }
var currentAppName: String? { get }
var currentWindowTitle: String? { get }

func startNewSession(appName: String, windowTitle: String)
func endCurrentSession()
```

**Thread safety:** Properties are `private(set)` (publicly read-only). No synchronization; concurrent reads from background threads may see stale data. Access from main thread only.

**Idempotency:** `endCurrentSession()` is safe to call with no active session (early return).

### `HabitDatabase`
```swift
static let shared: HabitDatabase

// Entry operations
func incrementEntry(habitId: UUID, date: Date)
func decrementEntry(habitId: UUID, date: Date)
func addEntry(_ entry: HabitEntry)
func getEntry(for habitId: UUID, on date: Date) -> HabitEntry?
func deleteEntry(id: UUID)
func getEntries(for habitId: UUID, from: Date?, to: Date?) -> [HabitEntry]

// Habit CRUD
func createHabit(_ habit: Habit)
func updateHabit(_ habit: Habit)
func deleteHabit(id: UUID)
func getAllHabits() -> [Habit]
func getHabit(byId id: UUID) -> Habit?

// Statistics
func getStreak(for habit: Habit) -> HabitStreak
func getStatistics(for habit: Habit) -> HabitStatistics
```

### `WeeklyLogDatabase`
```swift
static let shared: WeeklyLogDatabase

// Entry CRUD
func createEntry(_ entry: WeeklyLogEntry)
func updateEntry(_ entry: WeeklyLogEntry)
func deleteEntry(id entryId: UUID)
func getAllEntries() -> [WeeklyLogEntry]
func getEntriesForWeek(startingFrom weekStartDate: Date) -> [WeeklyLogEntry]
func getEntriesForDate(_ date: Date) -> [WeeklyLogEntry]

// Category colors
func getCategoryColor(for categoryName: String) -> String?
func setCategoryColor(for categoryName: String, color: String)
func getAllCategories() -> [String]
func getCategoryTotals(for weekStartDate: Date) -> [(category: String, total: Double)]
```

## 6. Internal Logic Details

### AppMonitor: Hybrid Monitoring Strategy
```
App Changes: Event-driven (instant)
├── NSWorkspace.didActivateApplicationNotification
└── Calls appDidActivate() → delegate callback

Window Changes: Polling (2s interval)
├── Timer.scheduledTimer(withTimeInterval: 2.0)
├── Calls checkWindowTitleChange()
├── Compares against lastWindowTitle
└── Only fires delegate if title actually changed

Elapsed Time: Timer (1s interval)
└── Fires appMonitorDidUpdateElapsedTime() for UI updates
```

### SessionManager: Session Lifecycle
```
startNewSession(appName, windowTitle):
├── Get or create AppUsage record (increments visit count)
├── Get or create WindowUsage record (increments visit count)
└── Create UsageSession with startTime = now

endCurrentSession():
├── Guard: return if no active session
├── Calculate duration = now - session.startTime
├── database.endSession(id:) [async]
├── database.updateWindowTime(id:duration:) [async]
├── database.updateAppTime(id:duration:) [async]
└── Clear currentSession, currentWindow, currentApp
```

### Database Thread Safety Pattern
```swift
// Pattern used in all database classes
private let dbQueue = DispatchQueue(label: "...", qos: .utility)

// Reads: sync (caller waits for result)
func getEntry(...) -> HabitEntry? {
    return dbQueue.sync { 
        // unsafe SQL operations
    }
}

// Writes: async (fire-and-forget)
func createHabit(...) {
    dbQueue.async {
        // unsafe SQL operations
        DispatchQueue.main.async { self.lastUpdate = Date() }
    }
}

// Writes needing immediate UI feedback: sync
func incrementEntry(...) {
    dbQueue.sync {
        // unsafe SQL operations
        DispatchQueue.main.async { self.lastUpdate = Date() }
    }
}
```

### Habit Streak Algorithm (HabitDatabase.getStreak)
```
1. Group entries by calendar day
2. Iterate days in descending order
3. For each day:
   - If habit completed: increment tempStreak, update longestStreak
   - If not completed: reset tempStreak, break current streak
4. currentStreak = consecutive completions ending today/yesterday
5. longestStreak = maximum consecutive completions ever
```

### Validation Strategy
- **HabitDatabase**: No validation; assumes valid `Habit`/`HabitEntry` structs
- **WeeklyLogDatabase**: `timeSpent` capped at 2.0 hours in model init
- **SessionManager**: Guards against nil session/window/app in `endCurrentSession()`

## 7. Data Contracts

### HabitDatabase Schemas
```sql
-- habits table
id TEXT PRIMARY KEY,
name TEXT NOT NULL,
icon TEXT NOT NULL,
color TEXT NOT NULL,
type TEXT NOT NULL,           -- "checkbox" | "timer" | "counter"
frequency TEXT NOT NULL,      -- "daily" | "weekly" | "monthly"
target_value REAL NOT NULL DEFAULT 1.0,
reminder_time REAL,           -- nullable Unix timestamp
reminder_enabled INTEGER NOT NULL DEFAULT 0,
created_at REAL NOT NULL,
is_archived INTEGER NOT NULL DEFAULT 0

-- habit_entries table
id TEXT PRIMARY KEY,
habit_id TEXT NOT NULL,
date REAL NOT NULL,           -- Unix timestamp
value REAL NOT NULL DEFAULT 0.0,
notes TEXT,
created_at REAL NOT NULL,
FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
```

### WeeklyLogDatabase Schemas
```sql
-- weekly_log_entries table
id TEXT PRIMARY KEY,
date REAL NOT NULL,
category TEXT NOT NULL,
task TEXT NOT NULL,
time_spent REAL NOT NULL,
progress_note TEXT NOT NULL DEFAULT '',
win_note TEXT NOT NULL DEFAULT '',
is_win_of_day INTEGER NOT NULL DEFAULT 0,
created_at REAL NOT NULL

-- weekly_log_category_colors table
category_name TEXT PRIMARY KEY,
color TEXT NOT NULL
```

**Breaking-change risk areas:**
- Adding columns to `habit_entries` requires updating `extractEntry()` column indices
- Changing `entryColumns` constant in `WeeklyLogDatabase` affects all SELECT queries
- Modifying `HabitType` or `HabitFrequency` raw values breaks existing data

## 8. Failure Modes

**Known failure cases:**
- Accessibility permission not granted → `WindowTitleProvider.getWindowTitle()` returns empty string
- App doesn't support Accessibility → empty string returned
- Database file corrupted → `sqlite3_open` fails, `db` remains nil, all operations become no-ops

**Silent failure risks:**
- `extractEntry()` / `extractHabit()` force-unwrap UUID strings; malformed data crashes
- SQL errors logged to console but not surfaced to UI
- Timer continues running after `stopMonitoring()` if called from deinit during app termination

**Race conditions:**
- `SessionManager` assumes single-threaded access; concurrent `startNewSession()` calls cause data corruption
- `AppMonitor` timers fire on run loop; app termination during timer callback may cause issues

**Memory issues:**
- `AppMonitor` holds `weak var delegate` - safe, but delegate must not be deallocated while monitoring
- SQLite connections closed in `deinit`; ensure databases not deallocated during active queries

**Performance bottlenecks:**
- 2-second window polling interval is a compromise; faster polling increases CPU/battery usage
- Streak calculation in `getStreak()` iterates all entries; O(n) complexity
- No caching; every `getEntries()` call queries database

## 9. Observability

**Logs produced:**
- `"Error opening habits database"` - `HabitDatabase` init failure
- `"Error opening weekly log database"` - `WeeklyLogDatabase` init failure  
- `"Habits SQL Error: <message>"` - SQL execution errors
- `"SQL Error: <message>"` - WeeklyLog SQL execution errors

**Metrics to track:**
- Session duration distribution
- Window polling success rate (non-empty titles)
- Database query latency
- Streak calculation time for users with many entries

**Debug strategy:**
- Check `~/Library/Application Support/Stride/` for database files
- Use `sqlite3` CLI to inspect: `sqlite3 habits.db "SELECT * FROM habits;"`
- Enable Accessibility debugging in Console.app
- Add prints to `checkWindowTitleChange()` for window tracking issues

**How to test locally:**
```swift
// Test AppMonitor
let monitor = AppMonitor()
monitor.delegate = self
monitor.startMonitoring()
// Switch apps, observe delegate callbacks

// Test SessionManager
let sessionManager = SessionManager()
sessionManager.startNewSession(appName: "Test", windowTitle: "Window")
Thread.sleep(forTimeInterval: 2.0)
sessionManager.endCurrentSession()
// Verify session persisted in UsageDatabase

// Test HabitDatabase
let db = HabitDatabase.shared
let habit = Habit(name: "Test", icon: "star", color: "#FF0000")
db.createHabit(habit)
print(db.getAllHabits())
```

## 10. AI Agent Instructions

**How to modify this feature:**
1. Read all 5 Swift files in this folder before editing
2. Understand the thread-safety pattern: public methods wrap `dbQueue.sync/async`
3. Maintain separation: AppMonitor for events, SessionManager for lifecycle, databases for persistence

**Files that must be read before editing:**
- All files in this folder
- `Sources/Stride/Models.swift` (for `UsageDatabase`, `AppUsage`, `WindowUsage`, `UsageSession`)
- `Sources/Stride/Models/HabitModels.swift` (for `Habit`, `HabitEntry`)
- `Sources/Stride/Models/WeeklyLogModels.swift` (for `WeeklyLogEntry`)

**Safe refactoring rules:**
- Adding columns to database schemas requires: ALTER TABLE migration + `extractEntry()` update
- Changing timer intervals in `AppMonitor.Constants` is safe
- Adding new database methods must use `dbQueue.sync` (reads) or `dbQueue.async` (writes)
- Adding new `AppMonitorDelegate` methods is **NOT safe** - all methods are required (no default implementations exist); must update `AppState` (the sole conformer)

**Forbidden modifications:**
- DO NOT remove `weak` from `delegate` property (retain cycle risk)
- DO NOT call database methods outside `dbQueue` (thread safety violation)
- DO NOT use `SELECT *` in `WeeklyLogDatabase` (breaks column index assumptions)
- DO NOT change UUID string format in database bindings
- DO NOT add `AppMonitorDelegate` methods without updating `AppState` (the sole conformer)

## 11. Extension Points

**Safe addition locations:**
- New query methods in `HabitDatabase` / `WeeklyLogDatabase` (follow sync/async pattern)
- Additional statistics calculations in `HabitDatabase`
- New tables in databases (add `createXxxTable()` method + call from `createTables()`)

**How to extend without breaking contracts:**
1. For new database tables: add CREATE TABLE in `createTables()`, add CRUD methods following existing patterns
2. For new statistics: add computed property or method that queries existing tables
3. For new monitoring events: add delegate method to `AppMonitorDelegate` AND update `AppState` (no default implementations exist)

## 12. Technical Debt & TODO

**Weak areas:**
- No proper error propagation; database failures are silent
- Streak algorithm O(n) complexity; could be optimized with caching
- Sample data insertion blocks init; should be async

**Refactor targets:**
- Extract common database patterns into a `BaseDatabase` class
- Replace print statements with proper logging framework
- Add `Result<T, Error>` return types for database operations

**Simplification ideas:**
- Merge `HabitDatabase` and `WeeklyLogDatabase` into single database file
- Use SQLite WAL mode for better concurrent read performance
- Replace manual SQL with a lightweight query builder

**Missing:**
- Database migration versioning system
- Backup/export functionality
- Unit tests for streak calculations
- Accessibility permission status checking API
