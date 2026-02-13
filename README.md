# Stride

A macOS application that tracks your active application and window usage time. Stride provides detailed insights into how you spend your time on your computer by monitoring app switches and tracking session durations.

## Features

### Core Functionality
- **Real-time Activity Tracking**: Automatically detects when you switch between applications and windows
- **Session-based Monitoring**: Tracks continuous usage sessions with elapsed time display
- **Window-level Granularity**: Tracks individual windows within applications (e.g., different browser tabs)
- **Menu Bar Integration**: Quick access to current session info via the macOS menu bar

### Analytics & Insights
- **Application Statistics**: Total time spent, visit count, first/last seen dates for each app
- **Window History**: Track time spent in specific windows/tabs
- **Today View**: Editorial summary of today's core KPIs (Active Time, App Switches, Total Apps) with category distribution and top app rankings.
- **This Week**: 7-day usage charts with daily averages and most active days
- **Category-based Organization**: Group apps into customizable categories (Work, Entertainment, Social, etc.)

### Productivity Tools
- **Weekly Log**: Track focused work sessions with categories, tasks, and time spent (up to 2 hours per session)
  - Mark wins of the day
  - Calendar and list views
  - Progress notes for each session
  - Category-based color coding
- **Habit Tracker**: Build and maintain daily habits
  - Three tracking types: Checkbox, Timer, Counter
  - Streak tracking (current and longest)
  - GitHub-style contribution heatmap
  - Daily reminders with notifications
  - Detailed statistics and completion rates
  - Sample habits included for new users

### Categories & Organization
- 8 default categories: Work, Entertainment, Social, Productivity, Development, Communication, Utilities, Uncategorized
- Create custom categories with custom icons and colors
- Assign apps to categories manually or auto-categorization based on app names
- Filter and sort apps by category, time, or visits

### Data Management
- **SQLite Database**: Local storage for all usage data
- **Thread-safe Operations**: Asynchronous database writes prevent UI blocking
- **Data Persistence**: All tracking data is saved locally between sessions

## Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Swift**: 5.9 or later
- **Xcode**: 15.0 or later (for development)

## Installation

### Build from Source

```bash
# Clone the repository
git clone <repository-url>
cd Stride

# Build with Swift Package Manager
swift build

# Run the application
swift run Stride
```

### Important: Accessibility Permissions

Stride requires **Accessibility permissions** to detect window titles. On first launch:

1. Go to **System Settings → Privacy & Security → Accessibility**
2. Add Stride to the list
3. Enable the toggle

Without this permission, the app can only track application names, not window titles.

## Architecture

### Service-Oriented Architecture

The app follows a clean separation of concerns with specialized services:

#### Core Services

**AppState** (Coordinator)
- Singleton managing UI state and orchestrating services
- Conforms to `AppMonitorDelegate` for receiving app/window change notifications
- Coordinates between AppMonitor, SessionManager, and database layers

**AppMonitor** (Detection)
- Detects app and window changes using dual-strategy approach
- Event-driven app switching via `NSWorkspace.didActivateApplicationNotification`
- Polls window titles every 2 seconds (performance optimized)
- Provides elapsed time updates every 1 second

**SessionManager** (Tracking)
- Manages usage tracking session lifecycle
- Handles starting/ending sessions
- Coordinates with database for persistence
- Tracks current app, window, and session state

**WindowTitleProvider** (Accessibility)
- Retrieves window titles via macOS Accessibility APIs
- Handles permission checks and error cases

#### Database Layer

**UsageDatabase** (Main tracking data)
- Thread-safe SQLite database manager
- Tables: categories, applications, windows, sessions
- Serial dispatch queue for database operations
- Async writes for performance, sync reads for consistency

**HabitDatabase** (Habit tracking)
- Manages habits, entries, and streak calculations
- Tables: habits, habit_entries
- Provides statistics and completion rate calculations

**WeeklyLogDatabase** (Productivity sessions)
- Tracks focused work sessions
- Tables: weekly_log_entries, category_colors
- Supports calendar and list views with filtering

#### Models

**Core Tracking Models**
- **Category**: User-defined app categories with icons and colors
- **AppUsage**: Application statistics and metadata
- **WindowUsage**: Window-specific usage data
- **UsageSession**: Individual tracking sessions with start/end times

**Habit Tracking Models**
- **Habit**: Trackable habits with type, frequency, and targets
- **HabitEntry**: Individual completion records
- **HabitStreak**: Current and longest streak tracking
- **HabitStatistics**: Aggregated metrics for display

**Weekly Log Models**
- **WeeklyLogEntry**: Focus session with category, task, time (max 2 hours)
- **CategoryColor**: Custom colors for log categories

### Performance Optimizations

1. **Dual-Strategy Monitoring**:
   - App switches: Event-driven via `NSWorkspace` notifications (instant, no polling)
   - Window changes: 2-second polling (balances responsiveness with CPU usage)
   - Elapsed time: 1-second updates for UI display

2. **Thread Safety**:
   - UI updates dispatched to main queue
   - Database operations on serial queue
   - Async writes prevent blocking during frequent switches

3. **Empty Title Handling**:
   - Accessibility APIs may fail and return empty strings
   - Last valid window title preserved to prevent artificial session inflation

## Usage

### Main Window
The main window provides a navigation sidebar with these sections:

- **Live**: Live tracking view showing current app, window title, and session timer
- **All Apps**: Browse all tracked applications with search, filter, and sort options
- **Categories**: Manage custom categories and assign apps
- **Weekly Log**: Track focused work sessions (pomodoros) with categories and tasks
- **Today**: Editorial summary of today's core metrics and category mix
- **This Week**: Weekly usage charts and statistics
- **Habit Tracker**: Build and track daily habits with streaks and statistics

### Menu Bar
Click the eye icon in the menu bar for quick access to:
- Current active application
- Session elapsed time
- Open main window
- Quit application

## Data Storage

All data is stored locally in:
```
~/Library/Application Support/Stride/usage.db
~/Library/Application Support/Stride/habits.db
~/Library/Application Support/Stride/weekly_log.db
```

### Usage Database (usage.db)
- **categories**: Category definitions (id, name, icon, color, order)
- **applications**: App usage aggregates (name, category, time, visits)
- **windows**: Window usage data per app (title, time, visits)
- **sessions**: Individual tracking sessions (start, end, duration)

### Habit Database (habits.db)
- **habits**: Habit definitions (name, type, frequency, target, reminders)
- **habit_entries**: Daily completion records with values and notes

### Weekly Log Database (weekly_log.db)
- **weekly_log_entries**: Focus sessions (date, category, task, time, notes)
- **category_colors**: Custom color mappings for categories

## Development

### Project Structure
```
Stride/
├── Package.swift              # Swift Package Manager manifest
├── Sources/
│   └── Stride/
│       ├── StrideApp.swift    # App entry point & AppState
│       ├── Models.swift               # Core data models & UsageDatabase
│       ├── ContentView.swift          # Main content view
│       ├── Core/
│       │   ├── AppMonitor.swift
│       │   ├── SessionManager.swift
│       │   ├── WindowTitleProvider.swift
│       │   ├── HabitDatabase.swift
│       │   └── WeeklyLogDatabase.swift
│       ├── Models/
│       │   ├── HabitModels.swift
│       │   └── WeeklyLogModels.swift
│       └── Views/
│           ├── MainWindow/
│           ├── MenuBar/
│           ├── CurrentSession/
│           ├── Apps/
│           ├── Categories/
│           ├── Today/
│           ├── Trends/
│           ├── WeeklyLog/
│           ├── HabitTracker/
│           └── Shared/
└── .build/                     # Build artifacts
```

### Key Design Decisions

1. **SwiftUI + AppKit**: Uses SwiftUI for UI with AppKit integration for macOS-specific features
2. **SQLite over Core Data**: Direct SQLite for better control and performance
3. **Dual-strategy monitoring**: Event-driven for apps, 2-second polling for windows
4. **MenuBarExtra**: Always-available menu bar access alongside main window
5. **Service-oriented architecture**: Clear separation between monitoring, session management, and persistence
6. **Multiple databases**: Separate databases for usage tracking, habits, and weekly logs for better organization

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test
```

## Privacy & Security

- **Local-only storage**: No data leaves your device
- **No network access**: Application works entirely offline
- **Minimal permissions**: Only requires Accessibility for window title detection
- **Open source**: You can audit exactly what the app does

## License

[Add your license here]

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Acknowledgments

- Uses macOS Accessibility APIs for window detection
- Built with SwiftUI for modern macOS UI
- SQLite3 for reliable local data storage

## Troubleshooting

### App not tracking window titles
- Check Accessibility permissions in System Settings
- Some apps (like certain password managers) block Accessibility access

### High CPU usage
- Normal behavior during active use (polls every 2 seconds)
- Should be minimal when idle

### Database corruption
- Delete the database files to reset:
  - `~/Library/Application Support/Stride/usage.db`
  - `~/Library/Application Support/Stride/habits.db`
  - `~/Library/Application Support/Stride/weekly_log.db`
- You will lose all historical data

## Future Enhancements

- Export data to CSV/JSON
- Daily/weekly email reports
- Focus time goals and notifications
- Idle detection and automatic session pausing
- Cloud sync across devices
- Website tracking within browsers
