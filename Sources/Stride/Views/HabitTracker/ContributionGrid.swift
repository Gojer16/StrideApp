import SwiftUI

/**
 * ContributionGrid - GitHub-style contribution grid for habit tracking
 *
 * Features:
 * - 90-day grid (13 weeks) arranged horizontally
 * - 4-level intensity coloring (empty, light, medium, dark)
 * - Week labels on left (Mon, Wed, Fri)
 * - Today's square highlighted with white border
 * - Click to toggle, long-press for details
 * - Tooltip on hover showing exact value
 */
struct ContributionGrid: View {
    let habit: Habit
    let entries: [Date: Double]
    let onDayTap: (Date) -> Void
    let onDayLongPress: (Date) -> Void
    
    // 90 days = ~13 weeks
    private let daysToShow = 90
    private let columns = 7 // Days per week
    
    // Cell size
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Week labels
            weekLabels
            
            // Grid
            gridView
        }
    }
    
    // MARK: - Week Labels
    private var weekLabels: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<7) { dayIndex in
                if [0, 2, 4].contains(dayIndex) { // Mon, Wed, Fri
                    Text(weekdayLabel(for: dayIndex))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: "#808080"))
                        .frame(width: 20, height: cellSize)
                } else {
                    Color.clear
                        .frame(width: 20, height: cellSize)
                }
            }
        }
        .padding(.top, 16) // Align with first row
    }
    
    // MARK: - Grid View
    private var gridView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cellSpacing * 2) {
                ForEach(0..<weeksCount, id: \.self) { week in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { day in
                            if let date = getDateFor(week: week, day: day) {
                                DayCell(
                                    date: date,
                                    habit: habit,
                                    value: entries[Calendar.current.startOfDay(for: date)] ?? 0,
                                    isToday: date.isToday,
                                    baseColor: Color(hex: habit.color),
                                    onTap: { onDayTap(date) },
                                    onLongPress: { onDayLongPress(date) }
                                )
                                .frame(width: cellSize, height: cellSize)
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helpers
    private var weeksCount: Int {
        return (daysToShow + 6) / 7 // Round up to complete weeks
    }
    
    private func getDateFor(week: Int, day: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate days ago: (totalWeeks - week - 1) * 7 + (6 - day)
        let daysAgo = (weeksCount - week - 1) * 7 + (6 - day)
        return calendar.date(byAdding: .day, value: -daysAgo, to: today)
    }
    
    private func weekdayLabel(for index: Int) -> String {
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return weekdays[index]
    }
}

/**
 * Individual day cell in the contribution grid
 */
struct DayCell: View {
    let date: Date
    let habit: Habit
    let value: Double
    let isToday: Bool
    let baseColor: Color
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    
    private var intensity: DayIntensity {
        if value == 0 { return .empty }
        
        let progress: Double
        switch habit.type {
        case .checkbox:
            progress = value >= 1.0 ? 1.0 : 0.0
        case .timer, .counter:
            progress = min(value / habit.targetValue, 1.0)
        }
        
        if progress < 0.3 { return .light }
        if progress < 0.7 { return .medium }
        return .dark
    }
    
    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: 14, height: 14)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
            .onLongPressGesture {
                onLongPress()
            }
            .help(tooltipText)
    }
    
    private var cellColor: Color {
        switch intensity {
        case .empty:
            return Color(hex: "#1E2E24")  // heatmapEmpty from design system
        case .light:
            return baseColor.opacity(0.3)
        case .medium:
            return baseColor.opacity(0.6)
        case .dark:
            return baseColor
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return .white
        }
        return Color.clear
    }
    
    private var tooltipText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateStr = dateFormatter.string(from: date)
        
        let valueStr: String
        switch habit.type {
        case .checkbox:
            valueStr = value >= 1.0 ? "Done" : "Not done"
        case .timer:
            let mins = Int(value)
            valueStr = "\(mins) min"
        case .counter:
            valueStr = "\(Int(value)) times"
        }
        
        return "\(dateStr): \(valueStr)"
    }
}

enum DayIntensity {
    case empty
    case light
    case medium
    case dark
}

/**
 * Grid legend showing intensity scale
 */
struct GridLegend: View {
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#808080"))

            // Empty
            Rectangle()
                .fill(Color(hex: "#1E2E24"))
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            // Light
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            // Medium
            Rectangle()
                .fill(color.opacity(0.6))
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            // Dark
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text("More")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#808080"))
        }
    }
}
