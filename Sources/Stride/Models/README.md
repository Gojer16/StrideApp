# Feature: /Users/orlandoascanio/Desktop/screen-detector/Sources/Stride/Models

## 1. Purpose

**What this feature does:**
- Defines pure Swift value types (structs, enums) for the domain layer
- Contains `HabitModels.swift` for habit tracking entities (`Habit`, `HabitEntry`, `HabitStreak`)
- Contains `WeeklyLogModels.swift` for productivity logging (`WeeklyLogEntry`, `WeekInfo`)
- Provides Date extensions for week calculations (Monday-start enforced)

**What problem it solves:**
- **Decoupling**: Models have zero dependencies on SwiftUI, SQLite, or AppKit
- **Type Safety**: Replaces primitive strings with enums (`HabitType`, `HabitFrequency`)
- **Consistency**: Single source of truth for business rules (e.g., what defines a "completed" habit)

**What it explicitly does NOT handle:**
- Persistence (belongs in `Core/HabitDatabase.swift`, `Core/WeeklyLogDatabase.swift`)
- UI rendering (belongs in `Views/`)
- State management (belongs in `StrideApp.swift` AppState)
- Business logic requiring external services (belongs in `Core/`)

## 2. Scope Boundaries

**Belongs inside this feature:**
- Pure Swift `struct` and `enum` definitions
- Computed properties for formatting (e.g., `formattedTime`, `formattedTarget`)
- Initializers with default values and basic validation (clamping)
- Date extensions for domain-specific calendar math

**Must NEVER be added here:**
- `import SwiftUI`, `import AppKit`, `import SQLite3`
- `@Published`, `@State`, `@ObservedObject` property wrappers
- Database queries or file I/O
- Network requests or API calls

**Dependencies:**
- `Foundation` only (no external dependencies)

**Ownership boundaries:**
- Models are owned by whoever creates them (databases, views, view models)
- No singleton pattern in this folder - all models are value types

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Models Layer (Pure Swift)                     │
├─────────────────────────────┬───────────────────────────────────┤
│      HabitModels.swift      │      WeeklyLogModels.swift        │
├─────────────────────────────┼───────────────────────────────────┤
│  Enums:                     │  Structs:                         │
│  - HabitType                │  - WeeklyLogEntry                 │
│  - HabitFrequency           │  - CategoryColor                  │
│  - HabitFilter              │  - WeekInfo                       │
│                             │                                   │
│  Structs:                   │  Date Extensions:                 │
│  - Habit                    │  - startOfWeek (Monday)           │
│  - HabitEntry               │  - endOfWeek                      │
│  - HabitStreak              │  - weekInfo                       │
│  - HabitStatistics          │  - isInSameWeek                   │
│                             │  - formattedDay                   │
│  Date Extensions:           │  - shortDayName                   │
│  - isToday                  │  - dayOfMonth                     │
│  - isYesterday              │                                   │
│  - startOfMonth             │                                   │
│  - formattedShort           │                                   │
└─────────────────────────────┴───────────────────────────────────┘
```

**Design Principles:**
- All types are `struct` (value semantics) for thread safety
- All types conform to `Codable` for potential serialization
- All types conform to `Identifiable` for SwiftUI list compatibility
- Immutable by default; mutations return new instances

## 4. Folder Structure Explanation

### `HabitModels.swift`

**Enums:**

| Type | Cases | Purpose |
|------|-------|---------|
| `HabitType` | checkbox, timer, counter | How a habit is tracked |
| `HabitFrequency` | daily, weekly, monthly | Reset period |
| `HabitFilter` | all, daily, weekly, monthly, archived | List filtering |

**Structs:**

| Type | Key Properties | Purpose |
|------|----------------|---------|
| `Habit` | id, name, icon, color, type, frequency, targetValue | Habit definition |
| `HabitEntry` | id, habitId, date, value, notes | Single completion record |
| `HabitStreak` | currentStreak, longestStreak, lastCompletedDate | Streak tracking |
| `HabitStatistics` | totalEntries, completionRate, weeklyData | Aggregated metrics |

**Who calls it:**
- `HabitDatabase` - creates, reads, persists instances
- `HabitTrackerView` - displays and edits instances
- `HabitTrackerViewModel` - aggregates statistics

**Side effects:** None (pure value types)

### `WeeklyLogModels.swift`

**Structs:**

| Type | Key Properties | Purpose |
|------|----------------|---------|
| `WeeklyLogEntry` | id, date, category, task, timeSpent, progressNote, winNote, isWinOfDay | Focus session log |
| `CategoryColor` | categoryName, color | Category-to-color mapping |
| `WeekInfo` | startDate, endDate, weekNumber, year, days | Week metadata |

**Date Extensions:**
- `startOfWeek` - Returns Monday of the current week
- `endOfWeek` - Returns Sunday of the current week
- `weekInfo` - Returns `WeekInfo` struct
- `isInSameWeek(as:)` - Week comparison

**Who calls it:**
- `WeeklyLogDatabase` - creates, reads, persists instances
- `WeeklyLogView` - displays entries
- `WeeklyLogViewModel` - aggregates weekly data

**Side effects:** None (pure value types)

## 5. Public API

### HabitModels.swift

```swift
// MARK: - Enums

enum HabitType: String, Codable, CaseIterable {
    case checkbox, timer, counter
    var displayName: String
    var icon: String  // SF Symbol name
}

enum HabitFrequency: String, Codable, CaseIterable {
    case daily, weekly, monthly
    var displayName: String
}

enum HabitFilter: String, CaseIterable {
    case all, daily, weekly, monthly, archived
}

// MARK: - Habit

struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var type: HabitType
    var frequency: HabitFrequency
    var targetValue: Double
    var reminderTime: Date?
    var reminderEnabled: Bool
    var createdAt: Date
    var isArchived: Bool
    
    var formattedTarget: String  // e.g., "30 min", "8 times"
    
    static let sampleHabits: [Habit]
}

// MARK: - HabitEntry

struct HabitEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var habitId: UUID
    var date: Date
    var value: Double
    var notes: String
    var createdAt: Date
    
    var isCompleted: Bool  // value >= 1.0
    func formattedValue(for type: HabitType) -> String
}

// MARK: - HabitStreak

struct HabitStreak: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    
    var isActive: Bool  // completed today or yesterday
}

// MARK: - HabitStatistics

struct HabitStatistics {
    let habit: Habit
    let totalEntries: Int
    let completionRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let totalValue: Double
    let averageValue: Double
    let weeklyData: [Date: Double]
    let monthlyData: [Date: Double]
    
    var formattedCompletionRate: String
    var formattedTotal: String
    var formattedAverage: String
}
```

### WeeklyLogModels.swift

```swift
// MARK: - WeeklyLogEntry

struct WeeklyLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var category: String
    var task: String
    var timeSpent: Double  // Hours, capped at 2.0
    var progressNote: String
    var winNote: String
    var isWinOfDay: Bool
    var createdAt: Date
    
    var timeInMinutes: Int
    var formattedTime: String
    var formattedHoursCount: String
    var formattedMinutes: String
}

// MARK: - CategoryColor

struct CategoryColor: Identifiable, Codable, Equatable {
    let id: UUID
    var categoryName: String
    var color: String  // Hex code
}

// MARK: - WeekInfo

struct WeekInfo {
    let startDate: Date  // Monday
    let endDate: Date    // Sunday
    let weekNumber: Int
    let year: Int
    
    var days: [Date]
    var formattedRange: String  // "Jan 13 - Jan 19, 2025"
}

// MARK: - Date Extensions

extension Date {
    var startOfWeek: Date  // Monday
    var endOfWeek: Date    // Sunday
    var weekInfo: WeekInfo
    func isInSameWeek(as date: Date) -> Bool
    var formattedDay: String  // "Mon, Jan 13"
    var shortDayName: String  // "Mon"
    var dayOfMonth: String    // "13"
}
```

## 6. Internal Logic Details

### Value Interpretation by HabitType

```
HabitType.checkbox:
├── value: 1.0 = completed, 0.0 = not completed
├── targetValue: always 1.0
└── isCompleted: value >= 1.0

HabitType.timer:
├── value: minutes spent
├── targetValue: target minutes
└── isCompleted: value >= targetValue

HabitType.counter:
├── value: count completed
├── targetValue: target count
└── isCompleted: value >= targetValue
```

### Time Spent Clamping (WeeklyLogEntry)

```swift
init(..., timeSpent: Double, ...) {
    self.timeSpent = min(timeSpent, 2.0)  // Cap at 2 hours max
}
```

### Monday-Start Week Calculation

```swift
var startOfWeek: Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
    components.weekday = 2  // 2 = Monday in Gregorian
    return calendar.date(from: components) ?? self
}
```

### Streak Active Check

```swift
var isActive: Bool {
    guard let lastDate = lastCompletedDate else { return false }
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let lastDay = calendar.startOfDay(for: lastDate)
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    
    return lastDay == today || lastDay == yesterday
}
```

## 7. Data Contracts

### Habit JSON Schema

```json
{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Morning Meditation",
    "icon": "figure.mind.and.body",
    "color": "#4A7C59",
    "type": "timer",
    "frequency": "daily",
    "targetValue": 10,
    "reminderTime": 734234234.234,
    "reminderEnabled": true,
    "createdAt": 734230000.0,
    "isArchived": false
}
```

### HabitEntry JSON Schema

```json
{
    "id": "660e8400-e29b-41d4-a716-446655440000",
    "habitId": "550e8400-e29b-41d4-a716-446655440000",
    "date": 734234234.0,
    "value": 15.0,
    "notes": "Great session!",
    "createdAt": 734234240.0
}
```

### WeeklyLogEntry JSON Schema

```json
{
    "id": "770e8400-e29b-41d4-a716-446655440000",
    "date": 734234234.0,
    "category": "Development",
    "task": "Code review",
    "timeSpent": 1.5,
    "progressNote": "Reviewed PR #42",
    "winNote": "Found critical bug",
    "isWinOfDay": true,
    "createdAt": 734234240.0
}
```

**Breaking-change risk areas:**
- Changing `HabitType` or `HabitFrequency` raw values breaks database data
- Adding new `HabitType` requires updating all switch statements
- Modifying `Codable` keys breaks JSON/database compatibility

## 8. Failure Modes

**Known issues:**
- Force-unwrapped UUIDs in sample data (safe, but verbose)
- No negative value validation in initializers
- `timeSpent` capped silently at 2.0 hours (user not notified)

**Edge cases:**
- Empty strings for names/notes are allowed
- `reminderTime` can be nil (no reminder)
- Streak calculation assumes single timezone

**Thread safety:**
- All types are value types - inherently thread-safe
- No mutable shared state

## 9. Observability

**Logging:** None (pure value types have no side effects)

**Testing strategy:**
```swift
// Test HabitEntry completion logic
let entry = HabitEntry(habitId: UUID(), date: Date(), value: 1.5)
XCTAssertTrue(entry.isCompleted)

// Test time clamping
let logEntry = WeeklyLogEntry(category: "Test", task: "Task", timeSpent: 5.0)
XCTAssertEqual(logEntry.timeSpent, 2.0)  // Clamped to 2 hours

// Test week calculations
let monday = Date().startOfWeek
let calendar = Calendar.current
XCTAssertEqual(calendar.component(.weekday, from: monday), 2)  // Monday
```

## 10. AI Agent Instructions

**How to modify this feature:**
1. Read both Swift files before editing
2. Maintain `Codable` conformance for all new properties
3. Add default values to initializers for backward compatibility

**Files that must be read before editing:**
- `HabitModels.swift` - understand Habit/HabitEntry relationship
- `WeeklyLogModels.swift` - understand WeekInfo calculations
- `Core/HabitDatabase.swift` - verify database column mapping
- `Core/WeeklyLogDatabase.swift` - verify database column mapping

**Safe refactoring rules:**
- Adding computed properties is safe
- Adding new enums is safe
- Adding new struct properties requires: default value + Codable conformance
- Date extensions must be tested across timezone boundaries

**Forbidden modifications:**
- DO NOT add `import SwiftUI`, `import SQLite3`, or `import AppKit`
- DO NOT add `@Published`, `@State`, or other property wrappers
- DO NOT change raw values of existing enums (breaks database)
- DO NOT add methods with side effects (file I/O, network)

## 11. Extension Points

**Safe addition locations:**
- New enum cases (append only, never insert/reorder)
- New computed properties on existing structs
- New Date extensions for domain calculations
- New struct types for new features

**How to extend:**
```swift
// Adding a new HabitType (append to end)
enum HabitType: String, Codable, CaseIterable {
    case checkbox, timer, counter, duration  // New case at end
    
    var icon: String {
        switch self {
        case .checkbox: return "checkmark.square.fill"
        case .timer: return "timer"
        case .counter: return "number.circle.fill"
        case .duration: return "clock.fill"  // Handle new case
        }
    }
}

// Adding computed property
extension Habit {
    var isOverdue: Bool {
        guard frequency == .daily else { return false }
        return !HabitDatabase.shared.getEntry(for: id, on: Date())!.isCompleted
    }
}
```

## 12. Technical Debt & TODO

**Weak areas:**
- No negative value validation in initializers
- Silent clamping of `timeSpent` at 2.0 hours
- Hardcoded Monday-start week (locale-insensitive)
- Duplicate Date extensions across files (some in HabitModels, some in WeeklyLogModels)

**Refactor targets:**
- Consolidate all Date extensions into single location
- Add validation initializers that throw errors
- Consider `Measurement<UnitDuration>` for type-safe time values

**Simplification ideas:**
- Replace `value: Double` with type-safe associated values
- Use `Measurement<UnitDuration>` instead of raw minutes

**Missing:**
- Comprehensive unit tests for streak calculations
- Timezone-aware week boundaries
- Localization support for display strings
