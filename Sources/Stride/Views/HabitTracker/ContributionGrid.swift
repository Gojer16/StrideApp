import SwiftUI

/**
 * ContributionGrid - GitHub-style contribution grid for habit tracking.
 * 
 * Interaction Model:
 * - Click: Increment (+1 session)
 * - Option+Click: Decrement (-1 session)
 * - Click info icon: View history
 * - Hover: Shows contextual +/− and ℹ️ icons
 */
struct ContributionGrid: View {
    let habit: Habit
    let entries: [Date: Double]
    let onDayTap: (Date) -> Void // Legacy callback (not used with new model)
    let onShowHistory: (Date) -> Void
    let onIncrementTracked: () -> Void // Callback to track increments for hint system
    
    private let daysToShow = 91 // 13 weeks
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 4
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            weekLabels
            gridView
        }
    }
    
    private var weekLabels: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<7) { i in
                if [1, 3, 5].contains(i) {
                    Text(weekdayLabel(for: i))
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(Color(hex: "#999999"))
                        .frame(height: cellSize)
                } else {
                    Spacer().frame(height: cellSize)
                }
            }
        }
        .padding(.top, 4)
    }
    
    private var gridView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cellSpacing) {
                ForEach(0..<13, id: \.self) { week in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { day in
                            if let date = getDateFor(week: week, day: day) {
                                DayCell(
                                    date: date,
                                    habit: habit,
                                    value: entries[Calendar.current.startOfDay(for: date)] ?? 0,
                                    isToday: date.isToday,
                                    baseColor: Color(hex: habit.color),
                                    onIncrement: { 
                                        _ = HabitDatabase.shared.incrementEntry(habitId: habit.id, date: date)
                                        onIncrementTracked()
                                    },
                                    onDecrement: { _ = HabitDatabase.shared.decrementEntry(habitId: habit.id, date: date) },
                                    onShowHistory: { onShowHistory(date) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getDateFor(week: Int, day: Int) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysAgo = ((12 - week) * 7) + (6 - day)
        return calendar.date(byAdding: .day, value: -daysAgo, to: today)
    }
    
    private func weekdayLabel(for index: Int) -> String {
        ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][index]
    }
}

/**
 * DayCell - A tactile square that "pops" when clicked.
 * 
 * Interaction Model:
 * - Click: Increment (+1 session)
 * - Option+Click: Decrement (-1 session, deletes if reaches 0)
 * - Click info icon: View history
 * - Hover: Shows contextual +/− and ℹ️ icons
 */
struct DayCell: View {
    let date: Date
    let habit: Habit
    let value: Double
    let isToday: Bool
    let baseColor: Color
    
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onShowHistory: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var isHovered: Bool = false
    
    private var intensity: Double {
        if value == 0 { return 0 }
        if habit.type == .checkbox { return 1.0 }
        
        // 5-level system (0, 1, 2, 3, 4+)
        // We map value 1-4 to intensity 0.25 to 1.0
        return min(value / 4.0, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Base cell
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(cellColor)
                .frame(width: 12, height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.black.opacity(isToday ? 0.3 : 0), lineWidth: 1.5)
                )
            
            // Hover icons overlay
            if isHovered {
                HStack(spacing: 2) {
                    // Increment/Decrement icon
                    iconButton(
                        systemName: value > 0 ? "minus.circle.fill" : "plus.circle.fill",
                        action: { handleTap() }
                    )
                    
                    // Info/History icon (always visible on hover)
                    iconButton(
                        systemName: "info.circle.fill",
                        action: onShowHistory
                    )
                }
                .transition(.opacity)
            }
        }
        .scaleEffect(scale)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(tooltipText)
    }
    
    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 14, height: 14)
                
                Image(systemName: systemName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var cellColor: Color {
        if intensity == 0 { return Color.black.opacity(0.04) }
        
        // Level 1: 25% opacity
        // Level 2: 50% opacity
        // Level 3: 75% opacity
        // Level 4+: 100% (Solid Brand Color)
        return baseColor.opacity(0.25 + (intensity * 0.75))
    }
    
    private var tooltipText: String {
        let dateStr = date.formatted(date: .abbreviated, time: .omitted)
        let sessions = Int(value)
        return "\(dateStr): \(sessions) session\(sessions == 1 ? "" : "s")\nClick to add • Option+Click to remove • ℹ️ for history"
    }
    
    private func handleTap() {
        // Check if Option key is held
        let modifiers = NSEvent.modifierFlags
        
        if modifiers.contains(.option) && value > 0 {
            // Option+Click: Decrement
            shrinkEffect()
            onDecrement()
        } else {
            // Regular Click: Increment
            popEffect()
            onIncrement()
        }
    }
    
    private func popEffect() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 1.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
    
    private func shrinkEffect() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 0.6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
}
