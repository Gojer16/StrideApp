import SwiftUI

/**
 * HabitGridCard - A premium widget displaying habit consistency.
 * 
 * **Aesthetic: Warm Paper Pro**
 */
struct HabitGridCard: View {
    let habit: Habit
    let entries: [Date: Double]
    let streak: HabitStreak
    let statistics: HabitStatistics
    let isCollapsed: Bool
    
    let onDayTap: (Date) -> Void
    let onShowHistory: (Date) -> Void
    let onAddToday: () -> Void
    let onViewDetails: () -> Void
    let onIncrementTracked: () -> Void
    let onToggleCollapse: () -> Void
    
    @State private var isHovered = false
    
    // Design System - Warm Paper
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let brandGold = Color(hex: "#D4A853")
    private let accentColor: Color
    
    init(habit: Habit, entries: [Date: Double], streak: HabitStreak, statistics: HabitStatistics,
         isCollapsed: Bool,
         onDayTap: @escaping (Date) -> Void, onShowHistory: @escaping (Date) -> Void,
         onAddToday: @escaping () -> Void, onViewDetails: @escaping () -> Void,
         onIncrementTracked: @escaping () -> Void, onToggleCollapse: @escaping () -> Void) {
        self.habit = habit
        self.entries = entries
        self.streak = streak
        self.statistics = statistics
        self.isCollapsed = isCollapsed
        self.onDayTap = onDayTap
        self.onShowHistory = onShowHistory
        self.onAddToday = onAddToday
        self.onViewDetails = onViewDetails
        self.onIncrementTracked = onIncrementTracked
        self.onToggleCollapse = onToggleCollapse
        self.accentColor = Color(hex: habit.color)
    }
    
    var body: some View {
        Group {
            if isCollapsed {
                CollapsedHabitCard(
                    habit: habit,
                    streak: streak,
                    statistics: statistics,
                    onToggleCollapse: onToggleCollapse
                )
            } else {
                expandedCard
            }
        }
    }
    
    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: 1. Header & Current Streak
            headerSection
            
            // MARK: 2. Main Visualization
            ContributionGrid(
                habit: habit,
                entries: entries,
                onDayTap: onDayTap,
                onShowHistory: onShowHistory,
                onIncrementTracked: onIncrementTracked
            )
            .padding(.vertical, 4)
            
            // MARK: 3. Key Success Metrics
            HStack(spacing: 24) {
                statsSection
                Spacer()
                footerActions
            }
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isHovered ? accentColor.opacity(0.3) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.06 : 0.03), radius: 20, x: 0, y: 10)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { h in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = h
            }
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 16) {
                // Brand Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(textColor)

                    Text(habit.formattedTarget.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(secondaryText)
                        .tracking(1)
                }
            }

            Spacer()

            // Streak Pill
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(streak.currentStreak > 0 ? brandGold : secondaryText.opacity(0.3))

                Text("\(streak.currentStreak)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(streak.currentStreak > 0 ? textColor : secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.04)))
            .help(streakTooltip)
            
            // Chevron collapse button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    onToggleCollapse()
                }
            }) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(secondaryText)
                    .rotationEffect(.degrees(0))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 24) {
            miniStat(value: "\(statistics.totalEntries)", label: "DONE", color: accentColor)
            miniStat(value: statistics.formattedCompletionRate, label: "RATE", color: accentColor)
            miniStat(value: "\(streak.longestStreak)", label: "BEST", color: brandGold)
        }
    }
    
    private var footerActions: some View {
        HStack(spacing: 12) {
            Button(action: onAddToday) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Today")
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Button(action: onViewDetails) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.05))
                    .foregroundColor(secondaryText)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(secondaryText)
                .tracking(1)
        }
    }
    
    private var streakTooltip: String {
        if streak.currentStreak == 0 {
            return "No active streak. Complete this habit to start a new streak!"
        } else if streak.isActive {
            let status = streak.lastCompletedDate?.isToday == true ? "Completed today" : "Completed yesterday"
            return "\(status) • \(streak.currentStreak) day streak\nActive: completed today or yesterday. Resets if you miss 2 days in a row."
        } else {
            return "\(streak.currentStreak) day streak (inactive)\nComplete today to reactivate your streak!"
        }
    }
}
