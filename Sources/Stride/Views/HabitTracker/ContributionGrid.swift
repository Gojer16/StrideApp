import SwiftUI

/**
 * ContributionGrid - GitHub-style contribution grid for habit tracking.
 * 
 * Now with "Tactile Toggle" support:
 * - Left Click: Increment (+1 session)
 * - Right Click: Decrement (-1 session)
 * - Long Press: Open details
 */
struct ContributionGrid: View {
    let habit: Habit
    let entries: [Date: Double]
    let onDayTap: (Date) -> Void // Now interpreted as increment
    let onDayLongPress: (Date) -> Void
    
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
                                    onIncrement: { HabitDatabase.shared.incrementEntry(habitId: habit.id, date: date) },
                                    onDecrement: { HabitDatabase.shared.decrementEntry(habitId: habit.id, date: date) },
                                    onLongPress: { onDayLongPress(date) }
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
 */
struct DayCell: View {
    let date: Date
    let habit: Habit
    let value: Double
    let isToday: Bool
    let baseColor: Color
    
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onLongPress: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    private var intensity: Double {
        if value == 0 { return 0 }
        if habit.type == .checkbox { return 1.0 }
        
        // 5-level system (0, 1, 2, 3, 4+)
        // We map value 1-4 to intensity 0.25 to 1.0
        return min(value / 4.0, 1.0)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(cellColor)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.black.opacity(isToday ? 0.3 : 0), lineWidth: 1.5)
            )
            .scaleEffect(scale)
            .onTapGesture {
                popEffect()
                onIncrement()
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in onLongPress() }
            )
            .contextMenu {
                Button("Increment (+1)") { onIncrement() }
                Button("Decrement (-1)") { onDecrement() }
                Divider()
                Button("View Details") { onLongPress() }
            }
            .help("\(date.formatted(date: .abbreviated, time: .omitted)): \(Int(value)) sessions")
    }
    
    private var cellColor: Color {
        if intensity == 0 { return Color.black.opacity(0.04) }
        
        // Level 1: 25% opacity
        // Level 2: 50% opacity
        // Level 3: 75% opacity
        // Level 4+: 100% (Solid Brand Color)
        return baseColor.opacity(0.25 + (intensity * 0.75))
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
}
