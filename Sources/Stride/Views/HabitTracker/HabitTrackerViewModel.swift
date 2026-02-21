import Foundation
import Combine

class HabitTrackerViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var overallStreak: Int = 0
    @Published var completionRate: Double = 0.0
    @Published var totalCompletions: Int = 0
    @Published var bestStreak: Int = 0
    @Published var isLoading: Bool = false
    
    private let database = HabitDatabase.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        habits = database.getAllHabits()
        calculateOverallStats()
        isLoading = false
    }
    
    var filteredHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }
    
    func getEntries(for habit: Habit, lastDays: Int = 90) -> [Date: Double] {
        let ninetyDaysAgo = Date().daysAgo(lastDays)
        let entries = database.getEntries(for: habit.id, from: ninetyDaysAgo, to: Date())
        
        var entriesByDay: [Date: Double] = [:]
        for entry in entries {
            let dayStart = entry.date.startOfDay
            entriesByDay[dayStart, default: 0] += entry.value
        }
        return entriesByDay
    }
    
    func getStreak(for habit: Habit) -> HabitStreak {
        database.getStreak(for: habit)
    }
    
    func getStatistics(for habit: Habit) -> HabitStatistics {
        database.getStatistics(for: habit)
    }
    
    func createHabit(_ habit: Habit) {
        database.createHabit(habit)
        loadData()
    }
    
    func updateHabit(_ habit: Habit) {
        database.updateHabit(habit)
        loadData()
    }
    
    func deleteHabit(id: UUID) {
        database.deleteHabit(id: id)
        loadData()
    }
    
    func quickToggleToday(habit: Habit) {
        let today = Date()
        
        switch habit.type {
        case .checkbox:
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
        case .counter:
            let current = database.getEntry(for: habit.id, on: today)?.value ?? 0
            database.addEntry(HabitEntry(habitId: habit.id, date: today, value: current + 1))
        case .timer:
            break
        }
        
        loadData()
    }
    
    func saveEntry(habit: Habit, date: Date, value: Double, notes: String) {
        let existing = database.getEntries(for: habit.id, from: date.startOfDay, to: date).first
        let entry = HabitEntry(
            id: existing?.id ?? UUID(),
            habitId: habit.id,
            date: date,
            value: value,
            notes: notes
        )
        database.addEntry(entry)
        loadData()
    }
    
    func deleteEntry(id: UUID) {
        database.deleteEntry(id: id)
        loadData()
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
        
        let ninetyDaysAgo = Date().daysAgo(90)
        
        for habit in activeHabits {
            let streak = database.getStreak(for: habit)
            streaks.append(streak.currentStreak)
            bestStreakEver = max(bestStreakEver, streak.longestStreak)
            
            if let entry = database.getEntry(for: habit.id, on: Date()) {
                let isCompleted: Bool
                if habit.type == .checkbox {
                    isCompleted = entry.isCompleted
                } else {
                    isCompleted = entry.value >= habit.targetValue
                }
                if isCompleted {
                    completedToday += 1
                }
            }
            
            let entries = database.getEntries(for: habit.id, from: ninetyDaysAgo, to: Date())
            for entry in entries {
                let isCompleted: Bool
                if habit.type == .checkbox {
                    isCompleted = entry.isCompleted
                } else {
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
}
