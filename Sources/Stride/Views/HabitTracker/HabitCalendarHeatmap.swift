import SwiftUI

/**
 * HabitCalendarHeatmap - Visual calendar showing habit completion history
 *
 * Displays a grid of days with color intensity indicating completion level.
 * Dark Forest theme with moss green to amber gradient for intensity.
 */
struct HabitCalendarHeatmap: View {
    let data: [Date: Double]
    let habitType: HabitType
    let targetValue: Double
    
    // Show last 84 days (12 weeks) in a 7x12 grid
    private let daysToShow = 84
    private let columns = 7 // Days per week
    
    // Dark Forest theme colors
    private let emptyColor = Color(hex: "#1E2E24") // Very dark green
    private let lowColor = Color(hex: "#2D4A36") // Dark moss
    private let mediumColor = Color(hex: "#4A7C59") // Medium moss
    private let highColor = Color(hex: "#6B9B7A") // Light moss
    private let completeColor = Color(hex: "#D4A853") // Amber gold
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month labels
            monthLabels
            
            // Heatmap grid
            HStack(spacing: 3) {
                // Day of week labels
                VStack(spacing: 3) {
                    ForEach(["M", "W", "F"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(hex: "#808080"))
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Grid
                HStack(spacing: 3) {
                    ForEach(0..<12, id: \.self) { week in
                        VStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { day in
                                if let date = getDateFor(week: week, day: day) {
                                    HeatmapCell(
                                        intensity: getIntensity(for: date),
                                        isToday: date.isToday
                                    )
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 8) {
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#808080"))
                
                HStack(spacing: 3) {
                    ForEach(0..<5) { level in
                        Rectangle()
                            .fill(colorForLevel(level))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                }
                
                Text("More")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#808080"))
            }
        }
    }
    
    private var monthLabels: some View {
        let calendar = Calendar.current
        let today = Date()
        
        return HStack(spacing: 0) {
            ForEach(0..<12) { weekOffset in
                if let date = calendar.date(byAdding: .day, value: -(83 - weekOffset * 7), to: today),
                   let nextWeekDate = calendar.date(byAdding: .day, value: -(83 - (weekOffset + 1) * 7), to: today) {
                    
                    let currentMonth = calendar.component(.month, from: date)
                    let nextMonth = calendar.component(.month, from: nextWeekDate)
                    
                    if currentMonth != nextMonth || weekOffset == 0 {
                        Text(monthAbbreviation(currentMonth))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#9A9A9A"))
                            .frame(width: 15 * 7 / 12, alignment: .leading)
                    } else {
                        Spacer()
                            .frame(width: 15 * 7 / 12)
                    }
                }
            }
        }
        .padding(.leading, 15)
    }
    
    private func monthAbbreviation(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = Calendar.current.date(from: DateComponents(month: month))!
        return formatter.string(from: date)
    }
    
    private func getDateFor(week: Int, day: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        let daysAgo = (11 - week) * 7 + (6 - day)
        return calendar.date(byAdding: .day, value: -daysAgo, to: today)
    }
    
    private func getIntensity(for date: Date) -> Double {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        guard let value = data[dayStart] else {
            return 0
        }
        
        switch habitType {
        case .checkbox:
            return value >= 1.0 ? 1.0 : 0.0
        case .timer, .counter:
            return min(value / targetValue, 1.0)
        }
    }
    
    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return emptyColor
        case 1: return lowColor
        case 2: return mediumColor
        case 3: return highColor
        default: return completeColor
        }
    }
}

/**
 * Individual cell in the heatmap
 */
struct HeatmapCell: View {
    let intensity: Double
    let isToday: Bool
    
    // Dark Forest colors
    private let emptyColor = Color(hex: "#1E2E24")
    private let lowColor = Color(hex: "#2D4A36")
    private let mediumColor = Color(hex: "#4A7C59")
    private let highColor = Color(hex: "#6B9B7A")
    private let completeColor = Color(hex: "#D4A853")
    
    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: 12, height: 12)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isToday ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
            )
    }
    
    private var cellColor: Color {
        if intensity == 0 {
            return emptyColor
        } else if intensity < 0.25 {
            return lowColor.opacity(0.6 + intensity * 0.4)
        } else if intensity < 0.5 {
            return mediumColor.opacity(0.7 + intensity * 0.3)
        } else if intensity < 0.75 {
            return highColor.opacity(0.7 + intensity * 0.3)
        } else if intensity < 1.0 {
            return completeColor.opacity(0.6)
        } else {
            return completeColor
        }
    }
}