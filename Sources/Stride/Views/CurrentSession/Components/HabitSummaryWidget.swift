import SwiftUI

/**
 * HabitSummaryWidget - Compact habit tracking overview for the homepage.
 *
 * Displays:
 * - Current streak status
 * - Today's completion rate
 * - 14-day mini heatmap
 * - Quick toggle buttons for checkbox habits
 */
struct HabitSummaryWidget: View {
    @StateObject private var database = HabitDatabase.shared
    @State private var habits: [Habit] = []
    @State private var overallStreak = 0
    @State private var completionRate = 0.0
    @State private var isLoading = true
    
    // MARK: - Design Constants
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let mossColor = Color(hex: "#4A7C59")
    private let goldColor = Color(hex: "#D4A853")
    private let slateColor = Color(hex: "#5B7C8C")
    
    private var hasHabits: Bool {
        !habits.isEmpty
    }
    
    private var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with streak
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(mossColor)
                    
                    Text("Habits")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                if hasHabits {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(overallStreak)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(goldColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(goldColor.opacity(0.12))
                    )
                }
            }
            
            if isLoading {
                loadingPlaceholder
            } else if hasHabits {
                habitsContent
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
        .onChange(of: database.lastUpdate) {
            loadData()
        }
    }
    
    // MARK: - Content Views
    
    private var habitsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Completion rate and mini chart
            HStack(spacing: 20) {
                // Big completion percentage
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(completionRate * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                    
                    Text("TODAY")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                        .foregroundColor(secondaryText)
                }
                
                Divider()
                    .frame(height: 40)
                
                // Quick toggle section for checkbox habits
                quickToggleSection
            }
            
            // Mini heatmap for top habit
            if let topHabit = activeHabits.first {
                miniHeatmapSection(for: topHabit)
            }
        }
    }
    
    private var quickToggleSection: some View {
        let checkboxHabits = activeHabits.filter { $0.type == .checkbox }.prefix(3)
        
        return HStack(spacing: 8) {
            ForEach(Array(checkboxHabits), id: \.id) { habit in
                QuickHabitToggle(habit: habit) {
                    toggleHabit(habit)
                }
            }
        }
    }
    
    private func miniHeatmapSection(for habit: Habit) -> some View {
        let entries = getLast14DaysEntries(for: habit)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habit.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(secondaryText)
                    .lineLimit(1)
                
                Spacer()
                
                let streak = database.getStreak(for: habit)
                Text("\(streak.currentStreak) day streak")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(mossColor)
            }
            
            // 14-day mini grid
            HStack(spacing: 4) {
                ForEach(0..<14, id: \.self) { dayOffset in
                    guard let date = calendar.date(byAdding: .day, value: -(13 - dayOffset), to: today) else {
                        return AnyView(EmptyView())
                    }
                    
                    let isCompleted = entries[date] ?? 0 >= (habit.type == .checkbox ? 1 : habit.targetValue)
                    let isToday = calendar.isDate(date, inSameDayAs: today)
                    
                    return AnyView(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isCompleted ? mossColor : mossColor.opacity(0.1))
                            .frame(width: 16, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(isToday ? mossColor : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(mossColor.opacity(0.6))
                
                Text("Build consistency")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
            }
            
            Text("Track daily habits to see your streaks and progress here")
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
                    .frame(width: 60, height: 40)
                
                Spacer()
            }
            
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .redacted(reason: .placeholder)
    }
    
    // MARK: - Helpers
    
    private func getLast14DaysEntries(for habit: Habit) -> [Date: Double] {
        let calendar = Calendar.current
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        let entries = database.getEntries(for: habit.id, from: fourteenDaysAgo, to: Date())
        
        var entriesByDay: [Date: Double] = [:]
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            entriesByDay[dayStart, default: 0] += entry.value
        }
        return entriesByDay
    }
    
    private func toggleHabit(_ habit: Habit) {
        let today = Date()
        
        if habit.type == .checkbox {
            if let existing = database.getEntry(for: habit.id, on: today) {
                database.addEntry(HabitEntry(
                    id: existing.id,
                    habitId: habit.id,
                    date: today,
                    value: existing.isCompleted ? 0.0 : 1.0,
                    notes: existing.notes
                ))
            } else {
                database.addEntry(HabitEntry(habitId: habit.id, date: today, value: 1.0))
            }
        } else if habit.type == .counter {
            let current = database.getEntry(for: habit.id, on: today)?.value ?? 0
            database.addEntry(HabitEntry(habitId: habit.id, date: today, value: current + 1))
        }
        
        loadData()
    }
    
    private func loadData() {
        habits = database.getAllHabits()
        calculateStats()
        isLoading = false
    }
    
    private func calculateStats() {
        let active = habits.filter { !$0.isArchived }
        guard !active.isEmpty else {
            overallStreak = 0
            completionRate = 0
            return
        }
        
        var streaks: [Int] = []
        var completedToday = 0
        let today = Date()
        
        for habit in active {
            let streak = database.getStreak(for: habit)
            streaks.append(streak.currentStreak)
            
            if let entry = database.getEntry(for: habit.id, on: today) {
                if (habit.type == .checkbox && entry.isCompleted) ||
                   (habit.type != .checkbox && entry.value >= habit.targetValue) {
                    completedToday += 1
                }
            }
        }
        
        overallStreak = streaks.min() ?? 0
        completionRate = Double(completedToday) / Double(active.count)
    }
}

/**
 * QuickHabitToggle - Compact button for quick habit toggling.
 */
private struct QuickHabitToggle: View {
    let habit: Habit
    let action: () -> Void
    
    @State private var isCompleted: Bool = false
    @StateObject private var database = HabitDatabase.shared
    
    private let mossColor = Color(hex: "#4A7C59")
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isCompleted ? mossColor : mossColor.opacity(0.4))
                
                Text(habit.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isCompleted ? textColor : secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isCompleted ? mossColor.opacity(0.1) : Color.black.opacity(0.04))
            )
            .overlay(
                Capsule()
                    .stroke(isCompleted ? mossColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            checkCompletion()
        }
        .onChange(of: database.lastUpdate) {
            checkCompletion()
        }
    }
    
    private var textColor: Color {
        Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    private var secondaryText: Color {
        Color(red: 0.4, green: 0.4, blue: 0.4)
    }
    
    private func checkCompletion() {
        if let entry = database.getEntry(for: habit.id, on: Date()) {
            isCompleted = entry.isCompleted
        } else {
            isCompleted = false
        }
    }
}
