import SwiftUI

/**
 * WeeklyLogCalendarView - Displays weekly log entries in a calendar grid layout
 *
 * Features:
 * - 7-column grid (Mon-Sun)
 * - Color-coded blocks by category
 * - Block height proportional to time spent
 * - Gold stars for wins
 * - Tap to edit, swipe to delete
 *
 * Aesthetic: Warm Paper/Editorial Light
 */
struct WeeklyLogCalendarView: View {
    let entries: [WeeklyLogEntry]
    let weekStart: Date
    let onEdit: (WeeklyLogEntry) -> Void
    let onDelete: (WeeklyLogEntry) -> Void
    
    @State private var isAnimating = false
    
    private let backgroundColor = Color(hex: "#FAF8F4")
    private let cardBackground = Color.white
    private let accentColor = Color(hex: "#C75B39")
    private let textColor = Color(hex: "#2C2C2C")
    private let secondaryText = Color(hex: "#616161")
    private let winColor = Color(hex: "#D4A853")
    
    var weekDays: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)
        }
    }
    
    var entriesByDay: [Date: [WeeklyLogEntry]] {
        let calendar = Calendar.current
        var dict: [Date: [WeeklyLogEntry]] = [:]
        
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            dict[dayStart, default: []].append(entry)
        }
        
        return dict
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let isToday = Calendar.current.isDateInToday(day)
                    
                    VStack(spacing: 4) {
                        Text(day.shortDayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isToday ? accentColor : secondaryText)
                        
                        Text(day.dayOfMonth)
                            .font(.system(size: 15, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? accentColor : textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        isToday ? accentColor.opacity(0.08) : Color.clear
                    )
                }
            }
            .background(cardBackground)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Calendar grid
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let dayStart = Calendar.current.startOfDay(for: day)
                    let dayEntries = entriesByDay[dayStart] ?? []
                    
                    DayColumn(
                        entries: dayEntries,
                        onEdit: onEdit,
                        onDelete: onDelete
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Calendar.current.component(.weekday, from: day) == 1 || 
                        Calendar.current.component(.weekday, from: day) == 7
                        ? Color.black.opacity(0.015)
                        : Color.clear
                    )
                    .overlay(
                        Rectangle()
                            .fill(Color.black.opacity(0.04))
                            .frame(width: 1),
                        alignment: .trailing
                    )
                }
            }
            .background(cardBackground)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3)
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Day Column
private struct DayColumn: View {
    let entries: [WeeklyLogEntry]
    let onEdit: (WeeklyLogEntry) -> Void
    let onDelete: (WeeklyLogEntry) -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                if entries.isEmpty {
                    // Empty placeholder
                    Rectangle()
                        .fill(Color.black.opacity(0.02))
                        .frame(height: 60)
                        .overlay(
                            Text("-")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.black.opacity(0.15))
                        )
                } else {
                    ForEach(entries) { entry in
                        EntryBlock(entry: entry, onEdit: onEdit, onDelete: onDelete)
                    }
                }
            }
            .padding(8)
        }
    }
}

// MARK: - Entry Block
private struct EntryBlock: View {
    let entry: WeeklyLogEntry
    let onEdit: (WeeklyLogEntry) -> Void
    let onDelete: (WeeklyLogEntry) -> Void
    
    @State private var isHovering = false
    
    var categoryColor: String {
        WeeklyLogDatabase.shared.getCategoryColor(for: entry.category) ?? "#4ECDC4"
    }
    
    var blockHeight: CGFloat {
        // Minimum 50, max 150, scaled by time
        let baseHeight: CGFloat = 50
        let extraHeight = CGFloat(entry.timeSpent) * 30
        return min(baseHeight + extraHeight, 150)
    }
    
    var body: some View {
        Button(action: { onEdit(entry) }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(entry.category)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if entry.isWinOfDay {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                }
                
                Text(entry.task)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(2)
                
                Spacer()
                
                Text(entry.formattedMinutes)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: blockHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: categoryColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .opacity(isHovering ? 0.9 : 1.0)
            .scaleEffect(isHovering ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit") {
                onEdit(entry)
            }
            
            Button("Delete", role: .destructive) {
                onDelete(entry)
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}
