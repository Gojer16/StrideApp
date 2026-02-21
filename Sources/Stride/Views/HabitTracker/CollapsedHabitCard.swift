import SwiftUI

/**
 * CollapsedHabitCard - Minimal single-row view for collapsed habits.
 * 
 * Shows: Icon, Name, Streak, Success Rate, Chevron
 * Height: ~80pt
 * Aesthetic: Warm Paper Pro
 */
struct CollapsedHabitCard: View {
    let habit: Habit
    let streak: HabitStreak
    let statistics: HabitStatistics
    let onToggleCollapse: () -> Void
    
    @State private var isHovered = false
    
    // Design System - Warm Paper
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let brandGold = Color(hex: "#D4A853")
    private let accentColor: Color
    
    init(habit: Habit, streak: HabitStreak, statistics: HabitStatistics, onToggleCollapse: @escaping () -> Void) {
        self.habit = habit
        self.streak = streak
        self.statistics = statistics
        self.onToggleCollapse = onToggleCollapse
        self.accentColor = Color(hex: habit.color)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Habit icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            // Habit name
            Text(habit.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textColor)
            
            Spacer()
            
            // Streak badge
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(streak.currentStreak > 0 ? brandGold : secondaryText.opacity(0.3))
                
                Text("\(streak.currentStreak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(streak.currentStreak > 0 ? textColor : secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.04)))
            .help(streakTooltip)
            
            // Success rate
            Text(statistics.formattedCompletionRate)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .frame(minWidth: 50, alignment: .trailing)
            
            // Chevron button
            Button(action: onToggleCollapse) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(secondaryText)
                    .rotationEffect(.degrees(0)) // Will be animated by parent
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
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
