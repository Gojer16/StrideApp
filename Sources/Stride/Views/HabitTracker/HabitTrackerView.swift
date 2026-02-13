import SwiftUI

/**
 * HabitTrackerView - Main container for the habit tracking feature
 *
 * NEW: GitHub-style contribution grid design
 * - Separate mini-grids per habit (90 days)
 * - 4-level intensity coloring like GitHub contributions
 * - Week labels (Mon, Wed, Fri)
 * - Today's square highlighted
 * - All motivation metrics (streak, completion rate, best streak)
 * - Click to toggle, long-press for details
 */
struct HabitTrackerView: View {
    @StateObject private var database = HabitDatabase.shared
    
    @State private var habits: [Habit] = []
    @State private var selectedFilter: HabitFilter = .all
    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?
    @State private var detailHabit: Habit?
    @State private var selectedDay: SelectedDay?
    @State private var isAnimating = false
    @State private var overallStreak = 0
    @State private var completionRate = 0.0
    @State private var totalCompletions = 0
    @State private var bestStreak = 0
    
    // Dark Forest Theme - Design System
    private let forestBackground = Color(hex: "#0F1F17")
    private let forestCard = Color(hex: "#1A2820")
    private let brandPrimary = Color(hex: "#4A7C59")
    private let brandGold = Color(hex: "#D4A853")
    private let forestTextPrimary = Color(hex: "#F5F5F0")
    private let forestTextSecondary = Color(hex: "#9A9A9A")
    
    private var filteredHabits: [Habit] {
        switch selectedFilter {
        case .all:
            return habits.filter { !$0.isArchived }
        case .daily:
            return habits.filter { $0.frequency == .daily && !$0.isArchived }
        case .weekly:
            return habits.filter { $0.frequency == .weekly && !$0.isArchived }
        case .monthly:
            return habits.filter { $0.frequency == .monthly && !$0.isArchived }
        case .archived:
            return habits.filter { $0.isArchived }
        }
    }
    
    var body: some View {
        ZStack {
            forestBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -20)
                    
                    // Overall stats
                    statsSection
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    // Filter tabs
                    filterSection
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    // GitHub-style habit grids
                    habitsGridSection
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            HabitForm(onSave: { habit in
                database.createHabit(habit)
                loadData()
            })
        }
        .sheet(item: $editingHabit) { habit in
            HabitForm(habit: habit, onSave: { updatedHabit in
                database.updateHabit(updatedHabit)
                loadData()
            })
        }
        .sheet(item: $detailHabit) { habit in
            NavigationView {
                HabitDetailView(
                    habit: habit,
                    onEdit: {
                        detailHabit = nil
                        editingHabit = habit
                    },
                    onDelete: {
                        database.deleteHabit(id: habit.id)
                        loadData()
                    }
                )
            }
        }
        .sheet(item: $selectedDay) { day in
            DayDetailView(
                habit: day.habit,
                date: day.date,
                entry: day.entry,
                onSave: { value, notes in
                    saveDayEntry(habit: day.habit, date: day.date, value: value, notes: notes)
                },
                onDelete: {
                    if let entry = day.entry {
                        database.deleteEntry(id: entry.id)
                        loadData()
                    }
                }
            )
        }
        .onAppear {
            loadData()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                isAnimating = true
            }
        }
        .onChange(of: database.lastUpdate) { _, _ in
            loadData()
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Habit Tracker")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(forestTextPrimary)
                
                Text("Build consistency, one day at a time")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(forestTextSecondary)
            }
            
            Spacer()
            
            // Add button
            Button(action: { showingAddHabit = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("New Habit")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(brandPrimary)
                        .shadow(color: brandPrimary.opacity(0.3), radius: 8, x: 0, y: 3)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            // Overall streak
            StatBadge(
                icon: "flame.fill",
                value: "\(overallStreak)",
                label: "Day Streak",
                color: brandGold
            )
            
            // Completion rate
            StatBadge(
                icon: "checkmark.circle.fill",
                value: "\(Int(completionRate * 100))%",
                label: "Today",
                color: brandPrimary
            )
            
            // Total completions (last 90 days)
            StatBadge(
                icon: "number.circle.fill",
                value: "\(totalCompletions)",
                label: "Completed (90d)",
                color: Color(hex: "#6B9B7A")
            )
            
            // Best streak
            StatBadge(
                icon: "trophy.fill",
                value: "\(bestStreak)",
                label: "Best Streak",
                color: brandGold
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HabitFilter.allCases) { filter in
                    FilterButton(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        accentColor: brandPrimary
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }
    
    private var habitsGridSection: some View {
        VStack(spacing: 16) {
            ForEach(filteredHabits) { habit in
                let entries = getLast90DaysEntries(for: habit)
                let streak = database.getStreak(for: habit)
                let stats = database.getStatistics(for: habit)
                
                HabitGridCard(
                    habit: habit,
                    entries: entries,
                    streak: streak,
                    statistics: stats,
                    onDayTap: { date in
                        handleDayTap(habit: habit, date: date)
                    },
                    onDayLongPress: { date in
                        handleDayLongPress(habit: habit, date: date)
                    },
                    onAddToday: {
                        handleAddToday(habit: habit)
                    },
                    onViewDetails: {
                        detailHabit = habit
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredHabits.count)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        habits = database.getAllHabits()
        calculateOverallStats()
    }
    
    private func calculateOverallStats() {
        let activeHabits = habits.filter { !$0.isArchived }
        guard !activeHabits.isEmpty else {
            overallStreak = 0
            completionRate = 0
            totalCompletions = 0
            bestStreak = 0
            return
        }
        
        var streaks: [Int] = []
        var completedToday = 0
        var totalCompleted90Days = 0
        var bestStreakEver = 0
        
        let calendar = Calendar.current
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date())!
        
        for habit in activeHabits {
            let streak = database.getStreak(for: habit)
            streaks.append(streak.currentStreak)
            bestStreakEver = max(bestStreakEver, streak.longestStreak)
            
            // Check today's completion
            if let entry = database.getEntry(for: habit.id, on: Date()) {
                let isCompleted: Bool
                switch habit.type {
                case .checkbox:
                    isCompleted = entry.isCompleted
                default:
                    isCompleted = entry.value >= habit.targetValue
                }
                if isCompleted {
                    completedToday += 1
                }
            }
            
            // Count completions in last 90 days
            let entries = database.getEntries(for: habit.id, from: ninetyDaysAgo, to: Date())
            for entry in entries {
                let isCompleted: Bool
                switch habit.type {
                case .checkbox:
                    isCompleted = entry.isCompleted
                default:
                    isCompleted = entry.value >= habit.targetValue
                }
                if isCompleted {
                    totalCompleted90Days += 1
                }
            }
        }
        
        overallStreak = streaks.min() ?? 0
        completionRate = Double(completedToday) / Double(activeHabits.count)
        totalCompletions = totalCompleted90Days
        bestStreak = bestStreakEver
    }
    
    // MARK: - Helpers
    
    private func getLast90DaysEntries(for habit: Habit) -> [Date: Double] {
        let calendar = Calendar.current
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date())!
        let entries = database.getEntries(for: habit.id, from: ninetyDaysAgo, to: Date())
        
        var entriesByDay: [Date: Double] = [:]
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            // If multiple entries on same day, sum them (for counters/timers)
            entriesByDay[dayStart, default: 0] += entry.value
        }
        
        return entriesByDay
    }
    
    // MARK: - Actions
    
    private func handleDayTap(habit: Habit, date: Date) {
        let entry = database.getEntry(for: habit.id, on: date)
        
        // For today: quick toggle
        if date.isToday {
            quickToggleToday(habit: habit)
        } else {
            // For past days: open detail view
            selectedDay = SelectedDay(habit: habit, date: date, entry: entry)
        }
    }
    
    private func handleDayLongPress(habit: Habit, date: Date) {
        let entry = database.getEntry(for: habit.id, on: date)
        selectedDay = SelectedDay(habit: habit, date: date, entry: entry)
    }
    
    private func handleAddToday(habit: Habit) {
        let today = Date()
        let entry = database.getEntry(for: habit.id, on: today)
        selectedDay = SelectedDay(habit: habit, date: today, entry: entry)
    }

    private func quickToggleToday(habit: Habit) {
        let today = Date()
        
        switch habit.type {
        case .checkbox:
            if let existingEntry = database.getEntry(for: habit.id, on: today) {
                let newValue = existingEntry.isCompleted ? 0.0 : 1.0
                let updatedEntry = HabitEntry(
                    id: existingEntry.id,
                    habitId: habit.id,
                    date: today,
                    value: newValue,
                    notes: existingEntry.notes
                )
                database.addEntry(updatedEntry)
            } else {
                let entry = HabitEntry(habitId: habit.id, date: today, value: 1.0)
                database.addEntry(entry)
            }
            
        case .counter:
            let currentValue = database.getEntry(for: habit.id, on: today)?.value ?? 0
            let entry = HabitEntry(
                habitId: habit.id,
                date: today,
                value: currentValue + 1
            )
            database.addEntry(entry)
            
        case .timer:
            // For timer, open the detail view
            let entry = database.getEntry(for: habit.id, on: today)
            selectedDay = SelectedDay(habit: habit, date: today, entry: entry)
        }
        
        loadData()
    }
    
    private func saveDayEntry(habit: Habit, date: Date, value: Double, notes: String) {
        let calendar = Calendar.current
        
        // Check if entry exists for this day
        let existingEntries = database.getEntries(for: habit.id, from: calendar.startOfDay(for: date), to: date)
        
        if let existingEntry = existingEntries.first {
            // Update existing
            let updatedEntry = HabitEntry(
                id: existingEntry.id,
                habitId: habit.id,
                date: date,
                value: value,
                notes: notes
            )
            database.addEntry(updatedEntry)
        } else {
            // Create new
            let entry = HabitEntry(
                habitId: habit.id,
                date: date,
                value: value,
                notes: notes
            )
            database.addEntry(entry)
        }
        
        loadData()
    }
}

/**
 * Statistics badge for header
 */
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#9A9A9A"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#263328"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

/**
 * Filter selection button
 */
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color(hex: "#9A9A9A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? accentColor : Color.white.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
    }
}

/**
 * Helper struct for selected day in sheet
 */
struct SelectedDay: Identifiable {
    let id = UUID()
    let habit: Habit
    let date: Date
    let entry: HabitEntry?
}
