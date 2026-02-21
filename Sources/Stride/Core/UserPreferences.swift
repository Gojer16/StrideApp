import Foundation
import SwiftUI

/**
 * UserPreferences - Centralized manager for app-wide user settings.
 * 
 * Uses @AppStorage for automatic UserDefaults persistence.
 * Singleton pattern ensures consistent state across the app.
 */
final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    // MARK: - Habit Tracker Preferences
    
    /// Tracks if user has seen the Option+Click modifier hint
    @AppStorage("hasSeenHabitModifierHint") var hasSeenHabitModifierHint: Bool = false
    
    /// Total number of habit increments performed (used to trigger hint)
    @AppStorage("totalHabitIncrements") var totalHabitIncrements: Int = 0
    
    /// Habit collapse states stored as JSON dictionary [UUID: Bool]
    @AppStorage("habitCollapseStates") private var habitCollapseStatesJSON: String = "{}"
    
    // MARK: - Day Boundary Preferences
    
    /// Hour (0-23) when the user's day starts. Default is 0 (midnight).
    /// Sessions before this hour count as the previous calendar day.
    @AppStorage("dayStartHour") var dayStartHour: Int = 0
    
    // MARK: - Idle Detection Preferences
    
    /// Idle threshold in seconds. Default is 65 seconds.
    /// Sessions pause when no keyboard/mouse input detected for this duration.
    @AppStorage("idleThresholdSeconds") private var _idleThresholdSeconds: Int = 65
    
    /// Idle threshold as TimeInterval with validation (15-300 seconds)
    var idleThreshold: TimeInterval {
        get {
            let validated = max(15, min(300, _idleThresholdSeconds))
            return TimeInterval(validated)
        }
        set {
            _idleThresholdSeconds = Int(max(15, min(300, newValue)))
        }
    }
    
    private init() {}
    
    // MARK: - Helper Methods
    
    /// Increment the habit action counter
    func recordHabitIncrement() {
        totalHabitIncrements += 1
    }
    
    /// Check if modifier hint should be shown
    var shouldShowModifierHint: Bool {
        return totalHabitIncrements >= 3 && !hasSeenHabitModifierHint
    }
    
    /// Mark modifier hint as seen
    func dismissModifierHint() {
        hasSeenHabitModifierHint = true
    }
    
    // MARK: - Habit Collapse State Management
    
    private var habitCollapseStates: [String: Bool] {
        get {
            guard let data = habitCollapseStatesJSON.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                habitCollapseStatesJSON = json
            }
        }
    }
    
    /// Check if a habit is collapsed
    func isHabitCollapsed(id: UUID) -> Bool {
        return habitCollapseStates[id.uuidString] ?? false
    }
    
    /// Set collapse state for a habit
    func setHabitCollapsed(id: UUID, collapsed: Bool) {
        var states = habitCollapseStates
        states[id.uuidString] = collapsed
        habitCollapseStates = states
    }
    
    /// Collapse all habits
    func collapseAllHabits(ids: [UUID]) {
        var states = habitCollapseStates
        for id in ids {
            states[id.uuidString] = true
        }
        habitCollapseStates = states
    }
    
    /// Expand all habits
    func expandAllHabits(ids: [UUID]) {
        var states = habitCollapseStates
        for id in ids {
            states[id.uuidString] = false
        }
        habitCollapseStates = states
    }
    
    /// Check if any collapse state exists (for smart default logic)
    var hasAnyCollapseState: Bool {
        return !habitCollapseStates.isEmpty
    }
    
    // MARK: - Logical Day Calculation
    
    /// Returns the start of the logical "today" based on the day start hour setting.
    /// If current time is before dayStartHour, returns the previous day's boundary.
    var logicalStartOfToday: Date {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        // If we're before the day start hour, use yesterday's boundary
        if currentHour < dayStartHour {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            var components = calendar.dateComponents([.year, .month, .day], from: yesterday)
            components.hour = dayStartHour
            return calendar.date(from: components)!
        } else {
            // Use today's boundary
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = dayStartHour
            return calendar.date(from: components)!
        }
    }
    
    /// Returns true if the current time is in "extended day" mode
    /// (i.e., after midnight but before the day start hour)
    var isInExtendedDay: Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        return dayStartHour > 0 && currentHour < dayStartHour
    }
    
    /// Returns the logical date for display purposes.
    /// If in extended mode, returns yesterday's date.
    var logicalDate: Date {
        if isInExtendedDay {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        }
        return Date()
    }
}
