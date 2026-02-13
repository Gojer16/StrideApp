import SwiftUI

/**
 * HabitGridCard - Card displaying a single habit with GitHub-style contribution grid
 *
 * Shows:
 * - Habit icon, name, and color
 * - Contribution grid (90 days)
 * - Streak counter
 * - Completion stats (completed/total, percentage)
 * - Best streak ever
 * - Legend for intensity levels
 * - Quick actions (add today, view details)
 */
struct HabitGridCard: View {
    let habit: Habit
    let entries: [Date: Double]
    let streak: HabitStreak
    let statistics: HabitStatistics
    
    let onDayTap: (Date) -> Void
    let onDayLongPress: (Date) -> Void
    let onAddToday: () -> Void
    let onViewDetails: () -> Void
    
    @State private var isHovered = false
    
    // Design System - Dark Forest Theme
    private let forestCard = Color(hex: "#1A2820")
    private let forestTextPrimary = Color(hex: "#F5F5F0")
    private let forestTextSecondary = Color(hex: "#9A9A9A")
    private let brandGold = Color(hex: "#D4A853")
    private let accentColor: Color
    
    init(habit: Habit, entries: [Date: Double], streak: HabitStreak, statistics: HabitStatistics,
         onDayTap: @escaping (Date) -> Void, onDayLongPress: @escaping (Date) -> Void,
         onAddToday: @escaping () -> Void, onViewDetails: @escaping () -> Void) {
        self.habit = habit
        self.entries = entries
        self.streak = streak
        self.statistics = statistics
        self.onDayTap = onDayTap
        self.onDayLongPress = onDayLongPress
        self.onAddToday = onAddToday
        self.onViewDetails = onViewDetails
        self.accentColor = Color(hex: habit.color)  // Habit's brand color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Stats row
            statsSection
            
            // Contribution grid
            ContributionGrid(
                habit: habit,
                entries: entries,
                onDayTap: onDayTap,
                onDayLongPress: onDayLongPress
            )
            
            // Legend and actions
            footerSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(forestCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHovered ? accentColor.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // Icon and name
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(forestTextPrimary)

                    Text(habit.formattedTarget)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(forestTextSecondary)
                }
            }

            Spacer()

            // Streak badge
            HStack(spacing: 6) {
                Image(systemName: streak.currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(streak.currentStreak > 0 ? brandGold : Color(hex: "#666666"))

                Text("\(streak.currentStreak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(streak.currentStreak > 0 ? forestTextPrimary : Color(hex: "#808080"))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(streak.currentStreak > 0 ? brandGold.opacity(0.15) : Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 20) {
            StatItem(
                value: "\(statistics.totalEntries)",
                label: "Completed",
                icon: "checkmark.circle.fill",
                color: accentColor
            )
            
            StatItem(
                value: statistics.formattedCompletionRate,
                label: "Success Rate",
                icon: "chart.pie.fill",
                color: accentColor
            )
            
            StatItem(
                value: "\(streak.longestStreak)",
                label: "Best Streak",
                icon: "trophy.fill",
                color: brandGold
            )
            
            Spacer()
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        HStack {
            // Legend
            GridLegend(color: accentColor)
            
            Spacer()
            
            // Quick actions
            HStack(spacing: 12) {
                // Add today button
                Button(action: onAddToday) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Today")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accentColor.opacity(0.15))
                    )
                    .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
                
                // View details button
                Button(action: onViewDetails) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Details")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.05))
                    )
                    .foregroundColor(forestTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/**
 * Individual stat item in the stats row
 */
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#F5F5F0"))

                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(hex: "#808080"))
            }
        }
    }
}
