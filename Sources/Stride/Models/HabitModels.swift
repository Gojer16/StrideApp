import Foundation

/**
 * HabitType - Defines how a habit is tracked
 *
 * - checkbox: Simple boolean completion (e.g., "Take vitamins")
 * - timer: Time-based tracking (e.g., "Meditate for 10 minutes")
 * - counter: Numeric tracking (e.g., "Drink 8 glasses of water")
 */
enum HabitType: String, Codable, CaseIterable, Identifiable {
    case checkbox = "checkbox"
    case timer = "timer"
    case counter = "counter"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .checkbox: return "Checkbox"
        case .timer: return "Timer"
        case .counter: return "Counter"
        }
    }
    
    var icon: String {
        switch self {
        case .checkbox: return "checkmark.square.fill"
        case .timer: return "timer"
        case .counter: return "number.circle.fill"
        }
    }
}

/**
 * HabitFrequency - Defines the tracking period for a habit
 *
 * - daily: Reset every day (most common)
 * - weekly: Track X times per week
 * - monthly: Track X times per month
 */
enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

/**
 * Habit - Represents a trackable habit
 *
 * Tracks user-defined habits with customizable:
 * - Name and visual identity (icon, color)
 * - Tracking type (checkbox, timer, counter)
 * - Frequency (daily, weekly, monthly)
 * - Goal/target value
 * - Reminder time
 */
struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var color: String // Hex color code
    var type: HabitType
    var frequency: HabitFrequency
    var targetValue: Double // Target: minutes for timer, count for counter, 1.0 for checkbox
    var reminderTime: Date? // Optional daily reminder time
    var reminderEnabled: Bool
    var createdAt: Date
    var isArchived: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        type: HabitType = .checkbox,
        frequency: HabitFrequency = .daily,
        targetValue: Double = 1.0,
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.frequency = frequency
        self.targetValue = targetValue
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
    
    /// Returns formatted target based on type
    var formattedTarget: String {
        switch type {
        case .checkbox:
            return "Complete daily"
        case .timer:
            let hours = Int(targetValue) / 60
            let minutes = Int(targetValue) % 60
            if hours > 0 && minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else if hours > 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(minutes) min"
            }
        case .counter:
            return "\(Int(targetValue)) times"
        }
    }
    
    /// Sample habits for first-time users
    static let sampleHabits: [Habit] = [
        Habit(
            name: "Morning Meditation",
            icon: "figure.mind.and.body",
            color: "#4A7C59",
            type: .timer,
            frequency: .daily,
            targetValue: 10, // 10 minutes
            reminderEnabled: true
        ),
        Habit(
            name: "Drink Water",
            icon: "drop.fill",
            color: "#5A8C8C",  // Sea - Design System
            type: .counter,
            frequency: .daily,
            targetValue: 8, // 8 glasses
            reminderEnabled: true
        ),
        Habit(
            name: "Read",
            icon: "book.fill",
            color: "#D4A853",
            type: .timer,
            frequency: .daily,
            targetValue: 30, // 30 minutes
            reminderEnabled: false
        )
    ]
}

/**
 * HabitEntry - Represents a single completion entry for a habit
 *
 * Tracks when and how much a habit was completed.
 * Value interpretation depends on habit type:
 * - checkbox: 1.0 = completed, 0.0 = not completed
 * - timer: minutes spent
 * - counter: count completed
 */
struct HabitEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var habitId: UUID
    var date: Date
    var value: Double // Interpretation depends on habit type
    var notes: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        habitId: UUID,
        date: Date,
        value: Double,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.habitId = habitId
        self.date = date
        self.value = value
        self.notes = notes
        self.createdAt = createdAt
    }
    
    /// Returns true if this entry represents completion for checkbox habits
    var isCompleted: Bool {
        return value >= 1.0
    }
    
    /// Formats value based on habit type
    func formattedValue(for type: HabitType) -> String {
        switch type {
        case .checkbox:
            return isCompleted ? "Done" : "Not done"
        case .timer:
            let hours = Int(value) / 60
            let minutes = Int(value) % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(Int(value))m"
            }
        case .counter:
            return "\(Int(value))"
        }
    }
}

/**
 * HabitStreak - Represents streak information for a habit
 *
 * Tracks both current and longest streaks.
 * A streak is consecutive periods of habit completion.
 */
struct HabitStreak: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    
    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
    }
    
    /// Returns true if streak is active (completed today or yesterday)
    var isActive: Bool {
        guard let lastDate = lastCompletedDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        return lastDay == today || lastDay == yesterday
    }
}

/**
 * HabitStatistics - Aggregated statistics for a habit
 *
 * Provides calculated metrics for display in detail views.
 */
struct HabitStatistics {
    let habit: Habit
    let totalEntries: Int
    let completionRate: Double // 0.0 to 1.0
    let currentStreak: Int
    let longestStreak: Int
    let totalValue: Double // Total time for timers, total count for counters
    let averageValue: Double
    let weeklyData: [Date: Double] // Last 7 days of data
    let monthlyData: [Date: Double] // Last 30 days of data
    
    /// Formatted completion rate as percentage
    var formattedCompletionRate: String {
        return "\(Int(completionRate * 100))%"
    }
    
    /// Formatted total based on habit type
    var formattedTotal: String {
        switch habit.type {
        case .checkbox:
            return "\(totalEntries) completions"
        case .timer:
            let totalMinutes = Int(totalValue)
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m total"
            } else {
                return "\(minutes)m total"
            }
        case .counter:
            return "\(Int(totalValue)) total"
        }
    }
    
    /// Formatted average
    var formattedAverage: String {
        switch habit.type {
        case .checkbox:
            return formattedCompletionRate
        case .timer:
            let avgMinutes = Int(averageValue)
            return "\(avgMinutes)m avg"
        case .counter:
            return "\(Int(averageValue)) avg"
        }
    }
}

/**
 * HabitFilter - Filter options for habit list
 */
enum HabitFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case archived = "archived"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .archived: return "Archived"
        }
    }
}

// MARK: - Date Extensions

extension Date {
    /// Returns true if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Returns the start of the month for this date
    var startOfMonth: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
    
    /// Returns formatted date string for display
    var formattedShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}
