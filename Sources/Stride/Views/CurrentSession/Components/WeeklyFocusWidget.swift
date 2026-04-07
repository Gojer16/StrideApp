import SwiftUI

/**
 * WeeklyFocusWidget - Compact weekly log summary for the homepage.
 *
 * Displays:
 * - Current week's logged hours
 * - Daily activity indicator (which days have sessions)
 * - Count of "wins of the day"
 * - Quick "Log Session" button
 */
struct WeeklyFocusWidget: View {
    @State private var currentWeekStart: Date = Date().startOfWeek
    @State private var entries: [WeeklyLogEntry] = []
    @State private var isLoading = true
    
    // MARK: - Design Constants
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(hex: "#C75B39")
    private let winColor = Color(hex: "#D4A853")
    
    private var weeklyTotal: Double {
        entries.reduce(0) { $0 + $1.timeSpent }
    }
    
    private var weeklyMinutes: Int {
        entries.reduce(0) { $0 + $1.timeInMinutes }
    }
    
    private var winsCount: Int {
        entries.filter { $0.isWinOfDay }.count
    }
    
    private var hasData: Bool {
        !entries.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                    
                    Text("Weekly Focus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                if hasData {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("\(winsCount)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(winColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(winColor.opacity(0.15))
                    )
                }
            }
            
            if isLoading {
                loadingPlaceholder
            } else if hasData {
                weeklyContent
            } else {
                emptyState
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Content Views
    
    private var weeklyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Total hours display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", weeklyTotal))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                Text(weeklyTotal == 1 ? "hour" : "hours")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryText)
                    .padding(.leading, 2)
                
                Spacer()
                
                Text("(\(weeklyMinutes) min)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryText.opacity(0.7))
            }
            
            Divider()
                .opacity(0.5)
            
            // Week day indicators
            weekDayIndicators
        }
    }
    
    private var weekDayIndicators: some View {
        let calendar = Calendar.current
        let weekDays = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart)
        }
        
        return HStack(spacing: 0) {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                let dayTotal = dayTotal(for: day)
                let isToday = calendar.isDateInToday(day)
                let hasEntry = dayTotal > 0
                let isFuture = day > Date()
                
                VStack(spacing: 6) {
                    // Day letter
                    Text(dayLetter(for: day))
                        .font(.system(size: 10, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? accentColor : secondaryText.opacity(0.7))
                    
                    // Activity indicator
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                isFuture
                                    ? Color.clear
                                    : (hasEntry ? accentColor.opacity(min(0.15 + (dayTotal * 0.1), 0.6)) : Color.black.opacity(0.06))
                            )
                            .frame(width: 32, height: 32)
                        
                        if hasEntry {
                            Text(String(format: "%.0f", dayTotal))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(accentColor)
                        } else if !isFuture {
                            Text("-")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(secondaryText.opacity(0.4))
                        }
                    }
                    
                    // Win indicator
                    if hasWin(for: day) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(winColor)
                    } else {
                        Spacer()
                            .frame(height: 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(isFuture ? 0.4 : 1.0)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(accentColor.opacity(0.6))
                
                Text("Track your focus sessions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
            }
            
            Text("Log deep work sessions and mark wins of the day to build momentum")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 80, height: 40)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 32, height: 32)
                }
            }
        }
        .redacted(reason: .placeholder)
    }
    
    // MARK: - Helpers
    
    private func dayTotal(for day: Date) -> Double {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.timeSpent }
    }
    
    private func hasWin(for day: Date) -> Bool {
        let calendar = Calendar.current
        return entries.contains {
            calendar.isDate($0.date, inSameDayAs: day) && $0.isWinOfDay
        }
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func loadData() {
        entries = WeeklyLogDatabase.shared.getEntriesForWeek(startingFrom: currentWeekStart)
        isLoading = false
    }
}
