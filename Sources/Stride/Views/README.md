# Feature: /Users/orlandoascanio/Desktop/screen-detector/Sources/Stride/Views

## 1. Purpose

The Views directory constitutes the presentation layer of the Stride screen time tracking application, implementing all SwiftUI-based user interface components. This layer translates raw usage data into actionable, visually compelling dashboards while providing multiple navigation paths for different user workflows.

- **What this feature does:**
  - Renders seven primary navigation destinations via sidebar: Live Session, All Apps, Categories, Weekly Log, Today, This Week, and Habit Tracker
  - Provides real-time reactive UI updates via AppState environment object binding
  - Implements "Ambient Status" design philosophy where background colors and visual states respond to active application category changes
  - Manages both windowed (MainWindowView) and menu bar (MenuBarView) presentation contexts
  - Handles all user input through forms, taps, gestures, and context menus

- **What problem it solves:**
  - Transforms raw SQLite usage logs into editorial-quality visualizations with consistent typography and spacing
  - Provides contextual awareness through color-coded background meshes that subconsciously indicate productivity states
  - Offers multiple temporal views (Today, This Week, Weekly Log, Habits) for comprehensive time analysis
  - Supports macOS-native UX patterns including NavigationSplitView, sheet presentations, and context menus

- **Why it exists in the system:**
  - Serves as the sole entry point for all user-facing content in the application
  - Enforces the "Warm Paper" and "Glassmorphism" design tokens consistently across all views
  - Abstracts database complexity behind reactive SwiftUI state management

- **What it explicitly does NOT handle:**
  - Direct SQLite database operations (delegated to Core/Database layer)
  - NSWorkspace or accessibility API polling for app detection (handled in Core)
  - System-level menu bar extra management (handled by AppDelegate)
  - Background service execution or scheduling

## 2. Scope Boundaries

- **What belongs inside this feature:**
  - All SwiftUI `View` structs and their computed properties
  - `@State`, `@Binding`, `@StateObject`, and `@EnvironmentObject` properties for UI state
  - Custom view modifiers and styling extensions
  - Animation definitions and transition configurations
  - Preview providers with sample data

- **What must NEVER be added here:**
  - `import SQLite3` or direct database pointer manipulation
  - `NSWorkspace` event monitoring code
  - `AXUIElement` accessibility API calls
  - Business logic that modifies model state without going through database layer
  - Network requests or external API integrations

- **Dependencies on other features:**
  - **Models:** Imports `Habit`, `HabitEntry`, `HabitStreak`, `HabitStatistics` (all top-level in HabitModels.swift), `AppUsage`, `Category`, `WeeklyLogEntry`
  - **Core:** Depends on `AppState` (global reactive state), `UsageDatabase`, `HabitDatabase`, `WeeklyLogDatabase`
  - **Foundation:** Uses `Date`, `Calendar`, `TimeInterval`, `UUID` for data manipulation

- **Clear ownership boundaries:**
  - Views own only their presentation state
  - Data persistence is owned by database singletons in Core
  - Global application state (active app, current category, session timer) lives in AppState

## 3. Architecture Overview

- **High-level flow diagram:**
```
[ macOS App Launch ]
         |
         v
[ MainWindowView ] <--@EnvironmentObject AppState
         |
    [ NavigationSplitView ]
         |
    +----+----+----+----+----+----+-----+
    |    |    |    |    |    |     |
    v    v    v    v    v    v     v
[Live] [Apps] [Cat] [Log] [Today] [Week] [Habits]
    |    |    |    |    |    |     |
    +----+----+----+----+----+----+-----+
         |
    [ AppState (Reactive Updates) ]
         |
    [ Database Layer (SQLite) ]
```

- **Entry points:**
  - `MainWindowView.swift`: Root `NavigationSplitView` container with sidebar navigation (lines 10-106)
  - `MenuBarView.swift`: Independent view rendered inside NSStatusItem popover (lines 9-50)

- **Core modules and responsibilities:**
  - **MainWindow:** Navigation container, sidebar item selection state
  - **CurrentSession:** Real-time session timer, ambient background mesh, app branding display
  - **AllApps:** Searchable grid of tracked applications with category filtering
  - **Categories:** CRUD interface for user-defined category management
  - **WeeklyLog:** Pomodoro-style focus session tracking with calendar/list views
  - **Today:** Daily usage summary with category breakdown donut chart
  - **ThisWeek:** Weekly historical analysis with bar chart visualization
  - **HabitTracker:** GitHub-style contribution grid with streak tracking

- **State management strategy:**
  - Global: `@EnvironmentObject private var appState: AppState` for reactive cross-view updates
  - View-local: `@State private var habits: [Habit] = []` for storing loaded data (most views)
  - Database observation: `@StateObject private var database = HabitDatabase.shared` (HabitTrackerView only)
  - Transient: `@State private var isAnimating = false` for entrance animations
  - Form: Local `@State` copies of model data committed to database on explicit save actions

- **Data flow explanation:**
  1. View appears and calls database load function
  2. Database queries SQLite and returns typed structs
  3. View updates `@State` properties triggering SwiftUI reconciliation
  4. User interaction creates/updates/deletes model data
  5. View calls database mutation method
  6. Database commits to SQLite
  7. Database `lastUpdate` publisher fires
  8. Views observing `lastUpdate` reload their data

## 4. Folder Structure Explanation

### MainWindow/
- **MainWindowView.swift (106 lines):** Root navigation shell using NavigationSplitView. Defines sidebarItems array mapping indices to view builders. Uses @ViewBuilder switch statement for content switching. No side effects beyond selection state.

### CurrentSession/
- **CurrentSessionView.swift (338 lines):** Primary "Live" tab displaying real-time session. Contains ambientBackground Canvas mesh gradient (lines 96-119) using two overlapping ellipses at 60px blur radius. Animates color transitions over 2.0s easeInOut when appState.currentCategoryColor changes. Defines glassMaterial for macOS blur overlay.
- **QuickStatCard.swift:** Reusable compact metric display component.

### AllApps/
- **AllAppsView.swift (286 lines):** Searchable, filterable, sortable grid of all tracked applications. Uses NavigationSplitView with detail sidebar for app details. FilteredApps computed property applies searchText, selectedCategory, and sortOrder transforms. LoadData() calls UsageDatabase.shared.getAllApplications().
- **AppGridCard.swift (103 lines):** Individual app card in the lazy grid with usage statistics and category color indicator.
- **AppDetailSidebar.swift (117 lines):** Detail panel for selected app with category assignment dropdown and time statistics.

### Categories/
- **CategoryManagementView.swift (219 lines):** HSplitView with category list (left) and apps list (right). Provides CRUD operations for categories. Context menu for edit/delete on non-default categories.
- **CategoryRow.swift (87 lines):** Single row in the category list with app count badge and color indicator.
- **CategoryAppsListView.swift (193 lines):** Right-side panel showing apps assigned to selected category with add/remove functionality.
- **Modals/CategoryEditorView.swift:** Sheet for creating/editing category details (name, icon, color).
- **Modals/AssignAppsToCategoryView.swift:** Modal for bulk-assigning apps to a category with search.

### WeeklyLog/
- **WeeklyLogView.swift (289 lines):** Main container for focus session tracking. Provides Calendar/List toggle (line 15). Week navigation via previousWeek/nextWeek functions. Deletion confirmation overlay with asymmetric transition.
- **WeeklyLogCalendarView.swift (227 lines):** 7-column calendar grid with entry blocks sized proportionally to time spent.
- **WeeklyLogListView.swift (227 lines):** Alternative list-based view for weekly entries with row-by-row display.
- **WeeklyLogEntryForm.swift:** Form for creating/editing weekly log entries with task, category, time, and win toggle.

### Today/
- **TodayView.swift (371 lines):** Daily summary dashboard. SummaryMetricCard components for Active Time, App Switches, Total Apps. Category distribution uses manual Circle trim drawing (lines 151-173) for donut chart. Loads data via UsageDatabase.shared.getTodayTime() and aggregates by category.
- **TodayAppRow.swift (110 lines):** Individual app row in the top utilization list with progress bar.

### Trends/
- **WeeklyView.swift (499 lines):** Weekly reflection hub with bar chart visualization. DayRow components for detailed log. Interactive bar chart with selection state tracking (selectedDay: Int?). Loads UsageDatabase.shared.getTime() and getCategoryTotalsForWeek().

### HabitTracker/
- **HabitTrackerView.swift (421 lines):** Editorial dashboard with BentoStatCard grid. FilterChip navigation for All/Daily/Weekly/Monthly/Archived. HabitGridCard components with 90-day ContributionGrid. Sheet presentations for HabitForm and DayDetailView. Calculates statistics in calculateOverallStats() method.
- **HabitGridCard.swift (170 lines):** Card wrapper with header, ContributionGrid, and action buttons.
- **ContributionGrid.swift (152 lines):** GitHub-style 13-week heatmap grid. DayCell with tactile pop animation on tap. Context menu for increment/decrement. onDayLongPress opens detail sheet.
- **HabitCalendarHeatmap.swift (192 lines):** Alternative calendar-based heatmap visualization with monthly view.
- **HabitForm.swift:** Form for creating/editing habits with target, frequency, type settings.
- **HabitDetailView.swift:** Detailed view showing all entries for a habit with edit/delete.
- **HabitTimerView.swift:** Timer interface for timed habits with start/pause/reset.
- **HabitStreakBadge.swift:** Streak display component with flame icon.
- **HabitCard.swift (352 lines):** Compact habit card for lists with quick-complete button.
- **DayDetailView.swift (369 lines):** Sheet for viewing/editing a single day's entry with value input and notes.

### Shared/
- **EmptyDetailView.swift (49 lines):** Reusable placeholder for empty selection states.
- **DetailStatBox.swift (33 lines):** Compact stat display component.
- **DetailInfoRow.swift:** Key-value row for detail views with label and value.
- **AppCategoryPickerView.swift:** Reusable category selection picker with search.
- **DesignSystem.swift:** Centralized design tokens (colors, typography, spacing, shadows, animations).
- **DonutChart.swift:** Reusable donut chart component with legend support.

### ViewModels/
- **HabitTrackerViewModel.swift:** ObservableObject for habit data management, stats calculation, CRUD operations.
- **WeeklyLogViewModel.swift:** ObservableObject for weekly log data, week navigation, entry management.

### MenuBar/
- **MenuBarView.swift (66 lines):** Compact popover view for menu bar status item. Shows activeAppName, formattedTime, and Open/Quit buttons.

### ViewModels/
- **HabitTrackerViewModel.swift:** ObservableObject for habit data management, stats calculation, CRUD operations.
- **WeeklyLogViewModel.swift:** ObservableObject for weekly log data, week navigation, entry management.

## 5. Public API

### View Initializers
All views accept model objects and callback closures:

- `CurrentSessionView()`: No parameters, uses AppState environment
- `AllAppsView()`: No parameters
- `CategoryManagementView()`: No parameters
- `WeeklyLogView()`: No parameters, derives currentWeekStart from Date().startOfWeek
- `TodayView()`: No parameters
- `WeeklyView()`: No parameters
- `HabitTrackerView()`: No parameters
- `MenuBarView()`: No parameters, uses AppState environment

### Callback Types
```swift
// HabitTracker callbacks
let onDayTap: (Date) -> Void
let onDayLongPress: (Date) -> Void
let onAddToday: () -> Void
let onViewDetails: () -> Void

// Form callbacks
let onSave: (Habit) -> Void  // For create/update
let onDelete: () -> Void      // For delete confirmation
```

### Exported Components
- `BentoStatCard`: Rounded container for high-impact statistics
- `FilterChip`: Capsule-shaped toggle button
- `SummaryMetricCard`: KPI display with icon and animation delay
- `BlurView`: NSVisualEffectView bridge for macOS-native blurring
- `EmptyDetailView`: Placeholder for empty states

### Input Types
- Model objects: `Habit`, `AppUsage`, `Category`, `WeeklyLogEntry`, `HabitEntry`
- Primitive bindings: `String`, `Int`, `Date`, `Bool`
- Enums: `SortOrder` (time/name/visits), `ViewMode` (calendar/list), `HabitFilter` (all/daily/weekly/monthly/archived)

### Output Types
- All views conform to SwiftUI's `View` protocol, returning `some View`
- Callback closures use `Void` return type for side-effect-only operations

### Error Behavior
- Empty states display friendly messages with action buttons
- Deletion requires explicit confirmation overlay
- Database errors silently log to console; UI shows empty states
- NO skeleton loaders or spinners currently implemented (TODO)
- NO retry mechanism for failed database operations

### Edge Cases
- No categories: Show empty state with "Create Category" CTA
- No apps: Show empty state in AllAppsView
- No weekly entries: Show empty state in WeeklyLogView
- No habits: Show empty state in HabitTrackerView
- Selected day in future: Disable interaction in contribution grid
- Selected day in present: Allow quick toggle via tap

### Idempotency Notes
- Database create/update methods are idempotent (update-or-insert)
- View reloads on database.lastUpdate change ensure consistency
- Filter/sort operations on filteredApps are purely functional with no side effects

## 6. Internal Logic Details

### Ambient Mesh Algorithm (CurrentSessionView)
- Uses SwiftUI Canvas for high-performance gradient rendering
- Two overlapping ellipses with 60px blur radius
- Color bound to appState.currentCategoryColor
- 2.0s easeInOut animation for smooth transitions during app switches
- Base layer: solid white background
- Overlay: Color.white.opacity(0.4) for text legibility

### Contribution Grid Algorithm (HabitTracker)
- Displays 91 days (13 weeks x 7 days) in horizontal scroll
- Days calculated relative to current date: `daysAgo = ((12 - week) * 7) + (6 - day)`
- Intensity calculation: 0 (empty), 0.25 (25%), 0.5 (50%), 0.75 (75%), 1.0 (100%)
- Tap triggers pop animation (scale 1.0 -> 1.4 -> 1.0 over 200ms)
- Long press (>0.5s) opens detail sheet
- Context menu provides increment/decrement alternatives

### Streak Calculation (HabitTrackerView)
- Iterates through active habits
- For each habit, calls database.getStreak()
- Overall streak = minimum current streak across all habits (weakest link)
- Best streak = maximum longest streak across all habits

### Weekly Aggregation (WeeklyView/TodayView)
- Uses Calendar.current.date(byAdding: .day, value:) for date math
- getTime(for: Date) returns TimeInterval for that specific day
- getCategoryTotalsForWeek(startingFrom:) returns aggregated time per category
- Bar chart height = (item.time / maxTime) * 160 (capped at 160pt)

### Data Loading Pattern
```swift
// Standard pattern across all views
private func loadData() {
    // Direct database query
    habits = database.getAllHabits()
    // Computed property updates
    calculateOverallStats()
}

// Triggered by
.onAppear { loadData() }
// And reactive to database changes
.onChange(of: database.lastUpdate) { loadData() }
```

## 7. Data Contracts

### Habit Model
```swift
struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String          // SF Symbol name
    var color: String        // Hex color "#RRGGBB"
    var type: HabitType      // .checkbox, .counter, .timer
    var frequency: HabitFrequency  // .daily, .weekly, .monthly
    var targetValue: Double // Target for counter/timer types
    var isArchived: Bool
}
```

### AppUsage Model
```swift
struct AppUsage: Identifiable {
    let id: UUID
    var name: String
    var categoryId: String   // Lowercase UUID string
    var totalTimeSpent: TimeInterval
    var visitCount: Int
}
```

### Category Model
```swift
struct Category: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var order: Int
    var isDefault: Bool      // Cannot delete default categories
}
```

### WeeklyLogEntry Model
```swift
struct WeeklyLogEntry: Identifiable {
    let id: UUID
    var date: Date
    var task: String
    var category: String
    var timeSpent: Double    // In pomodoros (0.25 increments)
    var isWinOfDay: Bool
}
```

### Validation Rules
- Habit name: Non-empty, max 50 characters
- Category name: Non-empty, unique, max 30 characters
- Category color: Valid hex format "#RRGGBB" (uppercase, no alpha)
- WeeklyLog task: Non-empty, max 200 characters
- App name: Derived from system, read-only
- Date ranges: Never allow selection of future dates in contribution grids

### Date Extension Contracts
- `Date.startOfWeek`: Returns Monday 00:00:00 for the week containing the date
- `Date.startOfDay`: Returns 00:00:00 of the same calendar day
- `Date.isToday`: True if same calendar day as current system date
- `Date.shortDayName`: Three-letter uppercase day abbreviation ("MON", "TUE")
- All date math uses `Calendar.current` with default system timezone

### Breaking-change risk areas
- Database schema changes require migration logic in Core layer
- AppState property additions must have default values for existing views
- AppUsage.categoryId stored as lowercase UUID string - do NOT change to uppercase

## 8. Failure Modes

### Known failure cases
- **Empty database:** All views show appropriate empty state with CTA
- **Missing category for app:** Uses Category.uncategorizedId as fallback
- **Date boundary issues:** Uses Calendar.current.startOfDay() consistently to normalize
- **Large datasets:** Uses LazyVGrid for AllAppsView, LazyVStack for lists

### Silent failure risks
- Database errors log to console but don't surface to user
- Network timeouts not applicable (local-only app)
- File permission errors for database location may cause crashes

### Race conditions
- Rapid sheet presentations (navigation between sidebar items) can orphan sheets
- Mitigation: Use `item:` binding pattern for all sheet presentations
- Concurrent database writes from multiple views: SQLite handles via file-level locking

### Memory issues
- ContributionGrid with 365+ days would cause performance degradation
- Current limit of 91 days prevents excessive memory usage
- Large category lists: Uses horizontal scroll in category cards

### Performance bottlenecks
- Heavy data aggregation in calculateOverallStats() runs on main thread
- getTodayTime() called multiple times per app in TodayView loop
- Recommendation: Cache computed totals in database layer

## 9. Observability

### Logs produced
- No explicit logging in Views layer
- Database layer handles SQL query logging in debug builds
- Console print statements used sparingly for debugging

### Metrics to track
- View load times: Measure from onAppear to isAnimating = true
- Animation frame drops: Monitor during ContributionGrid scrolling
- Sheet presentation frequency: Track via analytics

### Debug strategy
- SwiftUI Previews available for all major views with sample data
- PreviewProvider implementations use static sample data
- Toggle dark/light mode via .colorScheme environment

## 9.5 Platform Integration

### Window Management
- MainWindowView instantiated by AppDelegate or main entry point
- Uses standard NSWindow with NavigationSplitView content
- Minimum size: 900x600, default: 1200x800
- WindowController responsibilities handled by SwiftUI lifecycle

### Menu Bar Connection
- MenuBarView rendered inside NSStatusItem popover
- Popover created and managed by AppDelegate
- View receives updates via AppState environment object

### Dark/Light Mode
- Supports both `.light` and `.dark` colorScheme via @Environment(\.colorScheme)
- Current enforcement: "Warm Paper" theme applies to Habit section regardless of system setting
- Other sections respect system preference
- Brand colors must have sufficient contrast in both modes

### Form Validation Strategy
- Validation performed in view layer before calling database
- Invalid state tracked via local @State (e.g., `isValid: Bool`, `validationError: String?`)
- Error messages displayed inline below form fields
- Save button disabled when form is invalid
- Database layer does NOT re-validate (trusts caller)

### Database.lastUpdate Contract
- Publisher type: `@Published var lastUpdate: Date` on database singletons
- Fires on: any create/update/delete operation
- Does NOT fire on: read-only queries
- Views observe via `.onChange(of: database.lastUpdate)` modifier
- Resolution: millisecond precision timestamp

### How to test locally
```bash
# Build the project
cd /Users/orlandoascanio/Desktop/screen-detector
swift build

# Run in debug mode
swift run Stride

# Test specific view with preview (in Xcode)
# Open Sources/Stride/Views/Today/TodayView.swift
# Press Cmd+Shift+Enter to build preview
```

## 10. AI Agent Instructions

### How an AI agent should modify this feature

**Adding a new navigation tab:**
1. Add a new case to sidebarItems array in MainWindowView (line 14-22)
2. Add corresponding index case in contentView @ViewBuilder switch (lines 85-105)
3. Create new view folder under Views/ with descriptive name
4. Implement view following existing patterns:
   - Use `@State private var data: [Model] = []` for local data storage
   - Use `@State private var isLoading = false` for loading states
   - Call load function in `.onAppear`
   - DO NOT use `@StateObject` for database - use the shared singleton directly

**Adding a new component:**
1. Identify appropriate Shared/ subfolder or create feature-specific folder
2. Follow naming convention: `{Feature}{Component}.swift`
3. Accept model objects and callback closures as parameters
4. Use design system constants for colors and spacing

**Modifying existing views:**
1. Read the complete file before making changes
2. Identify all @State, @Binding, @StateObject properties
3. Trace data flow: where does data load? where does it save?
4. Preserve animation timing constants (typically 0.6s response, 0.8 damping)

### What files must be read before editing
- MainWindowView.swift (to understand navigation structure)
- Any view being modified (complete file)
- Related model files in Sources/Stride/Models/
- Database access patterns from existing similar views

### Safe refactoring rules
- Never change @State property names without updating all references
- Animation timings follow guidelines, not hard requirements:
  - Entrance animations: `.spring(response: 0.6, dampingFraction: 0.8)`
  - Micro-interactions: `.spring(response: 0.3, dampingFraction: 0.7)`
  - Sheet transitions: `.spring(response: 0.3, dampingFraction: 0.8)`
- Keep design system constants in view scope (don't extract to globals)
- Maintain sheet presentation pattern using item: binding

### Forbidden modifications
- DO NOT add import SQLite3 to any view file
- DO NOT use @StateObject for database access (use shared singletons)
- DO NOT add network calls or external API logic
- DO NOT bypass AppState for global state needs
- DO NOT remove PreviewProvider implementations (they're documentation)
- DO NOT add new @Published properties to AppState without default values

## 11. Extension Points

### Where new functionality can be safely added

**New visualization types:**
- Add to Trends/ folder for chart implementations
- Follow WeeklyView pattern for bar charts
- Follow TodayView pattern for donut charts (manual Circle trim)

**New habit types:**
- Extend HabitType enum in Models
- Update HabitForm to handle new type
- Update DayCell intensity calculation for new visualization

**New category colors:**
- Add to Category.defaultCategories in Models
- Automatic reactivity through AppState.currentCategoryColor binding

**New detail views:**
- Add to appropriate feature folder
- Use sheet presentation pattern
- Follow DetailStatBox and DetailInfoRow patterns

### How to extend without breaking contracts
- Add new optional parameters with default values
- Add new computed properties without modifying existing ones
- Add new enum cases with default handling in switch statements
- Add new database methods without modifying existing signatures

## 12. Technical Debt & TODO

### Weak areas
- **ViewModel Extraction:** HabitTrackerView, WeeklyLogView, and AllAppsView contain heavy data aggregation logic in view bodies. Should be refactored into dedicated ObservableObject view models.
- **Duplicate Color Constants:** Each view defines local design system constants. Should consolidate into shared DesignSystem or Theme struct.
- **Manual Donut Chart:** TodayView uses manual Circle trim drawing. Should extract to reusable Chart component.
- **Date Math Duplication:** Each view implements its own date range calculations. Should consolidate into Date+Extensions.

### Refactor targets
- Extract data loading logic from views into dedicated ViewModel classes
- Create shared Theme/DesignSystem module with centralized color/spacing constants
- Build reusable Chart components (BarChart, DonutChart, HeatMap)
- Add Date helpers for startOfWeek, startOfDay, daysAgo calculations

### Simplification ideas
- Consolidate filter logic into reusable FilterBar component
- Create single glassMaterial modifier in Shared folder
- Standardize empty state views across all features
- Remove duplicate PreviewProvider implementations (use shared sample data)

### Performance improvements
- Cache UsageDatabase.getTodayTime() results in TodayView loop
- Consider Canvas-based rendering for ContributionGrid if extended beyond 1 year
- Add pagination to AllAppsView if app count exceeds 500
- Lazy load historical data in WeeklyView

---

**Generated:** February 21, 2026
**Version:** 1.0
**Maintainer:** Stride Development Team
