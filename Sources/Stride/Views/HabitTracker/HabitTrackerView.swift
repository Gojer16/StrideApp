import SwiftUI

/**
 * HabitTrackerView - A high-end editorial dashboard for habit formation.
 * 
 * **Aesthetic: Warm Paper Editorial**
 * - Warm cream backgrounds
 * - Bento-style statistics grid
 * - Magazine-style Serif typography for headers
 * - Staggered spring animations for all cards
 */
struct HabitTrackerView: View {
    @StateObject private var database = HabitDatabase.shared
    @StateObject private var preferences = UserPreferences.shared
    
    @State private var habits: [Habit] = []
    @State private var selectedFilter: HabitFilter = .all
    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?
    @State private var detailHabit: Habit?
    @State private var selectedDay: SelectedDay?
    @State private var isAnimating = false
    @State private var showModifierHint = false
    @State private var showHistorySidebar = false
    @State private var historyHabit: Habit?
    
    // Stats State
    @State private var overallStreak = 0
    @State private var completionRate = 0.0
    @State private var totalCompletions = 0
    @State private var bestStreak = 0
    
    // Design System - Warm Paper
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let brandPrimary = Color(hex: "#4A7C59") // Stride Moss
    private let brandGold = Color(hex: "#D4A853") // Stride Gold
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    private var filteredHabits: [Habit] {
        switch selectedFilter {
        case .all: return habits.filter { !$0.isArchived }
        case .daily: return habits.filter { $0.frequency == .daily && !$0.isArchived }
        case .weekly: return habits.filter { $0.frequency == .weekly && !$0.isArchived }
        case .monthly: return habits.filter { $0.frequency == .monthly && !$0.isArchived }
        case .archived: return habits.filter { $0.isArchived }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // MARK: 1. Editorial Header
                    headerSection
                        .padding(.top, 24)
                    
                    // MARK: 1.5. Modifier Hint Banner (conditional)
                    if showModifierHint {
                        ModifierHintBanner(onDismiss: {
                            preferences.dismissModifierHint()
                            showModifierHint = false
                        })
                        .padding(.horizontal, 40)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // MARK: 2. Bento Stats Grid
                    bentoStatsGrid
                    
                    // MARK: 3. Navigation Filters
                    filterSection
                    
                    // MARK: 4. Habit Contribution Cards
                    habitsGridSection
                    
                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 40)
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
        .overlay {
            if showHistorySidebar, let habit = historyHabit {
                HabitHistorySidebar(
                    habit: habit,
                    entries: database.getEntries(for: habit.id, from: Calendar.current.date(byAdding: .day, value: -90, to: Date())!, to: Date()),
                    onClose: {
                        showHistorySidebar = false
                        historyHabit = nil
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            loadData()
            withAnimation(DesignSystem.Animation.entrance.spring) {
                isAnimating = true
            }
        }
        .onChange(of: database.lastUpdate) {
            loadData()
        }
    }
    
    // MARK: - Layout Sections
    
    private var headerSection: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 8) {
                Text("STRIDE CONSISTENCY")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(brandPrimary)
                    .tracking(2)
                
                Text("Habit Tracker")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(textColor)
            }
            
            Spacer()
            
            Button(action: { showingAddAddHabit() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Habit")
                }
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(brandPrimary)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    private func showingAddAddHabit() {
        showingAddHabit = true
    }
    
    private var bentoStatsGrid: some View {
        HStack(spacing: 20) {
            // Main Highlight (Streak)
            BentoStatCard(
                title: "Day Streak",
                value: "\(overallStreak)",
                icon: "flame.fill",
                color: brandGold,
                isLarge: true
            )
            
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    BentoStatCard(
                        title: "Today",
                        value: "\(Int(completionRate * 100))%",
                        icon: "checkmark.circle.fill",
                        color: brandPrimary
                    )
                    BentoStatCard(
                        title: "90d Growth",
                        value: "\(totalCompletions)",
                        icon: "chart.line.uptrend.xyaxis",
                        color: Color(hex: "#6B9B7A")
                    )
                }
                
                BentoStatCard(
                    title: "Personal Record",
                    value: "\(bestStreak) Days",
                    icon: "trophy.fill",
                    color: brandGold,
                    isWide: true
                )
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.1), value: isAnimating)
    }
    
    private var filterSection: some View {
        HStack(spacing: 12) {
            ForEach(HabitFilter.allCases) { filter in
                FilterChip(
                    title: filter.displayName,
                    isSelected: selectedFilter == filter,
                    activeColor: brandPrimary
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = filter
                    }
                }
            }
            
            Spacer()
            
            // Global collapse/expand toggle
            Button(action: toggleAllHabits) {
                HStack(spacing: 6) {
                    Image(systemName: allHabitsCollapsed ? "chevron.down.circle" : "chevron.up.circle")
                        .font(.system(size: 14, weight: .bold))
                    Text(allHabitsCollapsed ? "Expand All" : "Collapse All")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.04))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.2), value: isAnimating)
    }
    
    private var habitsGridSection: some View {
        VStack(spacing: 24) {
            ForEach(Array(filteredHabits.enumerated()), id: \.element.id) { index, habit in
                let entries = getLast90DaysEntries(for: habit)
                let streak = database.getStreak(for: habit)
                let stats = database.getStatistics(for: habit)
                let isCollapsed = preferences.isHabitCollapsed(id: habit.id)
                
                HabitGridCard(
                    habit: habit,
                    entries: entries,
                    streak: streak,
                    statistics: stats,
                    isCollapsed: isCollapsed,
                    onDayTap: { date in handleDayTap(habit: habit, date: date) },
                    onShowHistory: { date in handleShowHistory(habit: habit, date: date) },
                    onAddToday: { handleAddToday(habit: habit) },
                    onViewDetails: { detailHabit = habit },
                    onIncrementTracked: { handleIncrementTracked() },
                    onToggleCollapse: { toggleHabitCollapse(habit: habit) }
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 30)
                .animation(DesignSystem.Animation.entrance.spring.delay(0.3 + Double(index) * 0.05), value: isAnimating)
            }
        }
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        habits = database.getAllHabits()
        calculateOverallStats()
        applySmartDefaultCollapseState()
    }
    
    private func calculateOverallStats() {
        let activeHabits = habits.filter { !$0.isArchived }
        guard !activeHabits.isEmpty else {
            overallStreak = 0; completionRate = 0; totalCompletions = 0; bestStreak = 0
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
            
            if let entry = database.getEntry(for: habit.id, on: Date()) {
                if (habit.type == .checkbox && entry.isCompleted) || (habit.type != .checkbox && entry.value >= habit.targetValue) {
                    completedToday += 1
                }
            }
            
            let entries = database.getEntries(for: habit.id, from: ninetyDaysAgo, to: Date())
            for entry in entries {
                if (habit.type == .checkbox && entry.isCompleted) || (habit.type != .checkbox && entry.value >= habit.targetValue) {
                    totalCompleted90Days += 1
                }
            }
        }
        
        overallStreak = streaks.min() ?? 0
        completionRate = Double(completedToday) / Double(activeHabits.count)
        totalCompletions = totalCompleted90Days
        bestStreak = bestStreakEver
    }
    
    private func getLast90DaysEntries(for habit: Habit) -> [Date: Double] {
        let calendar = Calendar.current
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date())!
        let entries = database.getEntries(for: habit.id, from: ninetyDaysAgo, to: Date())
        
        var entriesByDay: [Date: Double] = [:]
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            entriesByDay[dayStart, default: 0] += entry.value
        }
        return entriesByDay
    }
    
    // MARK: - Actions
    
    private func handleIncrementTracked() {
        preferences.recordHabitIncrement()
        
        // Check if we should show the hint
        if preferences.shouldShowModifierHint && !showModifierHint {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showModifierHint = true
            }
        }
    }
    
    private func handleDayTap(habit: Habit, date: Date) {
        if date.isToday { quickToggleToday(habit: habit) }
        else { selectedDay = SelectedDay(habit: habit, date: date, entry: database.getEntry(for: habit.id, on: date)) }
    }
    
    private func handleDayLongPress(habit: Habit, date: Date) {
        selectedDay = SelectedDay(habit: habit, date: date, entry: database.getEntry(for: habit.id, on: date))
    }
    
    private func handleShowHistory(habit: Habit, date: Date) {
        historyHabit = habit
        showHistorySidebar = true
    }
    
    private func handleAddToday(habit: Habit) {
        selectedDay = SelectedDay(habit: habit, date: Date(), entry: database.getEntry(for: habit.id, on: Date()))
    }
    
    // MARK: - Collapse State Management
    
    private var allHabitsCollapsed: Bool {
        return filteredHabits.allSatisfy { preferences.isHabitCollapsed(id: $0.id) }
    }
    
    private func toggleHabitCollapse(habit: Habit) {
        let currentState = preferences.isHabitCollapsed(id: habit.id)
        preferences.setHabitCollapsed(id: habit.id, collapsed: !currentState)
    }
    
    private func toggleAllHabits() {
        let habitIds = filteredHabits.map { $0.id }
        
        if allHabitsCollapsed {
            // Expand all with staggered animation
            for (index, id) in habitIds.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        preferences.setHabitCollapsed(id: id, collapsed: false)
                    }
                }
            }
        } else {
            // Collapse all with staggered animation
            for (index, id) in habitIds.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        preferences.setHabitCollapsed(id: id, collapsed: true)
                    }
                }
            }
        }
    }
    
    private func applySmartDefaultCollapseState() {
        // Only apply smart defaults if no collapse state exists yet
        guard !preferences.hasAnyCollapseState else { return }
        
        let today = Date()
        for habit in habits {
            let hasActivityToday = database.getEntry(for: habit.id, on: today) != nil
            // Expand habits with activity today, collapse others
            preferences.setHabitCollapsed(id: habit.id, collapsed: !hasActivityToday)
        }
    }

    private func quickToggleToday(habit: Habit) {
        let today = Date()
        if habit.type == .checkbox {
            if let existing = database.getEntry(for: habit.id, on: today) {
                database.addEntry(HabitEntry(id: existing.id, habitId: habit.id, date: today, value: existing.isCompleted ? 0.0 : 1.0, notes: existing.notes))
            } else {
                database.addEntry(HabitEntry(habitId: habit.id, date: today, value: 1.0))
            }
        } else if habit.type == .counter {
            let current = database.getEntry(for: habit.id, on: today)?.value ?? 0
            database.addEntry(HabitEntry(habitId: habit.id, date: today, value: current + 1))
        } else {
            selectedDay = SelectedDay(habit: habit, date: today, entry: database.getEntry(for: habit.id, on: today))
        }
        loadData()
    }
    
    private func saveDayEntry(habit: Habit, date: Date, value: Double, notes: String) {
        let calendar = Calendar.current
        let existing = database.getEntries(for: habit.id, from: calendar.startOfDay(for: date), to: date).first
        let entry = HabitEntry(id: existing?.id ?? UUID(), habitId: habit.id, date: date, value: value, notes: notes)
        database.addEntry(entry)
        loadData()
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

// MARK: - Components

struct BentoStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isLarge: Bool = false
    var isWide: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 24 : 12) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: isLarge ? 48 : 32, height: isLarge ? 48 : 32)
                    Image(systemName: icon).font(.system(size: isLarge ? 20 : 14, weight: .bold)).foregroundColor(color)
                }
                if isWide { Spacer() }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: isLarge ? 44 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    .tracking(1)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: isLarge ? .infinity : nil, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 15, x: 0, y: 5)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? activeColor : Color.white)
                .foregroundColor(isSelected ? .white : Color(red: 0.4, green: 0.4, blue: 0.4))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(isSelected ? 0.1 : 0.02), radius: 5, x: 0, y: 2)
                .overlay(Capsule().stroke(Color.black.opacity(isSelected ? 0 : 0.05), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
