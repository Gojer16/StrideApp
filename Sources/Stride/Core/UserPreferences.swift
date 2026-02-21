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
    
    // MARK: - Day Boundary Preferences
    
    /// Hour (0-23) when the user's day starts. Default is 0 (midnight).
    /// Sessions before this hour count as the previous calendar day.
    @AppStorage("dayStartHour") var dayStartHour: Int = 0
    
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
