import Foundation

/**
 * WeeklyLogEntry - Represents a single focus session entry
 *
 * Tracks productivity sessions with category, task, time spent, and notes.
 * Time is stored in hours where:
 * - 0.1 = 6 minutes
 * - 0.25 = 15 minutes  
 * - 0.5 = 30 minutes
 * - 1 = 60 minutes (1 hour)
 * - 2 = 120 minutes (2 hours max)
 */
struct WeeklyLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var category: String
    var task: String
    var timeSpent: Double  // In hours (max 2.0)
    var progressNote: String
    var winNote: String
    var isWinOfDay: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        category: String,
        task: String,
        timeSpent: Double,
        progressNote: String = "",
        winNote: String = "",
        isWinOfDay: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.category = category
        self.task = task
        // Cap at 2 hours maximum
        self.timeSpent = min(timeSpent, 2.0)
        self.progressNote = progressNote
        self.winNote = winNote
        self.isWinOfDay = isWinOfDay
        self.createdAt = createdAt
    }
    
    /// Returns time spent in minutes
    var timeInMinutes: Int {
        return Int(timeSpent * 60)
    }
    
    /// Returns formatted time display: "1.5 hours (90 min)"
    var formattedTime: String {
        let minutes = timeInMinutes
        if minutes < 60 {
            return "\(String(format: "%.2f", timeSpent)) hours (\(minutes) min)"
        } else {
            let hours = Int(timeSpent)
            let mins = minutes % 60
            if mins == 0 {
                return "\(String(format: "%.2f", timeSpent)) hours (\(hours)h)"
            } else {
                return "\(String(format: "%.2f", timeSpent)) hours (\(hours)h \(mins)m)"
            }
        }
    }
    
    /// Returns just the hours count with unit
    var formattedHoursCount: String {
        return "\(String(format: "%.2f", timeSpent)) hours"
    }
    
    /// Returns just the minutes
    var formattedMinutes: String {
        let minutes = timeInMinutes
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
}

/**
 * CategoryColor - Maps category names to user-selected colors
 *
 * Allows users to assign custom colors to their categories
 * for visual organization in the weekly log.
 */
struct CategoryColor: Identifiable, Codable, Equatable {
    let id: UUID
    var categoryName: String
    var color: String  // Hex color code
    
    init(
        id: UUID = UUID(),
        categoryName: String,
        color: String
    ) {
        self.id = id
        self.categoryName = categoryName
        self.color = color
    }
}

/**
 * Helper struct for week calculations
 */
struct WeekInfo {
    let startDate: Date  // Monday
    let endDate: Date    // Sunday
    let weekNumber: Int
    let year: Int
    
    /// Returns all 7 days of the week (Monday to Sunday)
    var days: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }
        return dates
    }
    
    /// Returns formatted week range: "Jan 13 - Jan 19, 2025"
    var formattedRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let yearStr = yearFormatter.string(from: startDate)
        
        return "\(startStr) - \(endStr), \(yearStr)"
    }
}

// MARK: - Date Extensions for Week Calculations

extension Date {
    /// Returns the start of the week (Monday) for this date
    var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        // Force Monday as first day (weekday 2 in Gregorian calendar)
        components.weekday = 2
        return calendar.date(from: components) ?? self
    }
    
    /// Returns the end of the week (Sunday) for this date
    var endOfWeek: Date {
        let calendar = Calendar.current
        let startOfWeek = self.startOfWeek
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }
    
    /// Returns week information for this date
    var weekInfo: WeekInfo {
        let calendar = Calendar.current
        let start = self.startOfWeek
        let end = self.endOfWeek
        let weekNumber = calendar.component(.weekOfYear, from: start)
        let year = calendar.component(.yearForWeekOfYear, from: start)
        return WeekInfo(startDate: start, endDate: end, weekNumber: weekNumber, year: year)
    }
    
    /// Returns true if this date is in the same week as another date
    func isInSameWeek(as date: Date) -> Bool {
        return self.startOfWeek == date.startOfWeek
    }
    
    /// Returns formatted date string: "Mon, Jan 13"
    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: self)
    }
    
    /// Returns short day name: "Mon"
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    /// Returns day of month: "13"
    var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }
}
