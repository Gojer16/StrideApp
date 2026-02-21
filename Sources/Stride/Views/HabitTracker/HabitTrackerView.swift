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
    
    @State private var habits: [Habit] = []
    @State private var selectedFilter: HabitFilter = .all
    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?
    @State private var detailHabit: Habit?
    @State private var selectedDay: SelectedDay?
    @State private var isAnimating = false
    
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
        .onAppear {
            loadData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
        .offset(y: isAnimating ? 0 : -20)
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
                
                HabitGridCard(
                    habit: habit,
                    entries: entries,
                    streak: streak,
                    statistics: stats,
                    onDayTap: { date in handleDayTap(habit: habit, date: date) },
                    onDayLongPress: { date in handleDayLongPress(habit: habit, date: date) },
                    onAddToday: { handleAddToday(habit: habit) },
                    onViewDetails: { detailHabit = habit }
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
    
    private func handleDayTap(habit: Habit, date: Date) {
        if date.isToday { quickToggleToday(habit: habit) }
        else { selectedDay = SelectedDay(habit: habit, date: date, entry: database.getEntry(for: habit.id, on: date)) }
    }
    
    private func handleDayLongPress(habit: Habit, date: Date) {
        selectedDay = SelectedDay(habit: habit, date: date, entry: database.getEntry(for: habit.id, on: date))
    }
    
    private func handleAddToday(habit: Habit) {
        selectedDay = SelectedDay(habit: habit, date: Date(), entry: database.getEntry(for: habit.id, on: Date()))
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
