import Foundation
import Combine

class WeeklyLogViewModel: ObservableObject {
    @Published var entries: [WeeklyLogEntry] = []
    @Published var currentWeekStart: Date
    @Published var isLoading: Bool = false
    
    private let database = WeeklyLogDatabase.shared
    
    var weekInfo: WeekInfo {
        currentWeekStart.weekInfo
    }
    
    var weeklyTotal: Double {
        entries.reduce(0) { $0 + $1.timeSpent }
    }
    
    var weeklyMinutes: Int {
        entries.reduce(0) { $0 + $1.timeInMinutes }
    }
    
    var winsCount: Int {
        entries.filter { $0.isWinOfDay }.count
    }
    
    init() {
        currentWeekStart = Date().startOfWeek
        loadEntries()
    }
    
    func loadEntries() {
        isLoading = true
        entries = database.getEntriesForWeek(startingFrom: currentWeekStart)
        isLoading = false
    }
    
    func previousWeek() {
        currentWeekStart = currentWeekStart.adding(weeks: -1)
        loadEntries()
    }
    
    func nextWeek() {
        currentWeekStart = currentWeekStart.adding(weeks: 1)
        loadEntries()
    }
    
    func createEntry(_ entry: WeeklyLogEntry) {
        _ = database.createEntry(entry)
        loadEntries()
    }
    
    func updateEntry(_ entry: WeeklyLogEntry) {
        _ = database.updateEntry(entry)
        loadEntries()
    }
    
    func deleteEntry(_ entry: WeeklyLogEntry) {
        _ = database.deleteEntry(id: entry.id)
        loadEntries()
    }
    
    func entries(for date: Date) -> [WeeklyLogEntry] {
        entries.filter { $0.date.isSameDay(as: date) }
    }
    
    func totalTime(for date: Date) -> Double {
        entries(for: date).reduce(0) { $0 + $1.timeSpent }
    }
}
