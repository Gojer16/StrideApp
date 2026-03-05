import Testing
import Foundation
@testable import Stride

@Suite("Weekly Log Tests")
struct WeeklyLogTests {
    private var database: WeeklyLogDatabase { WeeklyLogDatabase.shared }

    @Test("Weekly log CRUD persists and reflects updates")
    func weeklyLogCRUDRoundTrip() {
        let now = Date()
        let entryId = UUID()
        let prefix = "test-\(UUID().uuidString)"
        var entry = WeeklyLogEntry(
            id: entryId,
            date: now,
            category: "\(prefix)-Focus",
            task: "Deep Work",
            timeSpent: 1.0,
            progressNote: "Initial draft complete",
            winNote: "Finished chapter",
            isWinOfDay: true
        )

        defer {
            _ = database.deleteEntry(id: entryId)
        }

        let createResult = database.createEntry(entry)
        switch createResult {
        case .success:
            break
        case .failure(let error):
            Issue.record("createEntry failed: \(error.localizedDescription)")
        }

        let weekEntries = database.getEntriesForWeek(startingFrom: entry.date.startOfWeek)
        #expect(weekEntries.contains { $0.id == entryId })

        entry.task = "Deep Work Updated"
        entry.timeSpent = 1.5
        let updateResult = database.updateEntry(entry)
        switch updateResult {
        case .success:
            break
        case .failure(let error):
            Issue.record("updateEntry failed: \(error.localizedDescription)")
        }

        let dayEntries = database.getEntriesForDate(entry.date)
        let updated = dayEntries.first { $0.id == entryId }
        #expect(updated?.task == "Deep Work Updated")
        #expect(updated?.timeSpent == 1.5)

        let deleteResult = database.deleteEntry(id: entryId)
        switch deleteResult {
        case .success:
            break
        case .failure(let error):
            Issue.record("deleteEntry failed: \(error.localizedDescription)")
        }

        let remaining = database.getEntriesForWeek(startingFrom: entry.date.startOfWeek)
        #expect(remaining.contains { $0.id == entryId } == false)
    }

    @Test("getEntriesForDate respects calendar-day boundaries")
    func getEntriesForDateUsesMidnightBoundary() {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        let queryDate = dayStart.addingTimeInterval(12 * 3600)

        let inDayId = UUID()
        let nextDayId = UUID()
        let prefix = "test-\(UUID().uuidString)"

        let inDayEntry = WeeklyLogEntry(
            id: inDayId,
            date: dayStart.addingTimeInterval(23 * 3600),
            category: "\(prefix)-A",
            task: "Inside boundary",
            timeSpent: 0.5
        )

        let nextDayEntry = WeeklyLogEntry(
            id: nextDayId,
            date: dayStart.addingTimeInterval((24 + 8) * 3600),
            category: "\(prefix)-B",
            task: "Outside boundary",
            timeSpent: 0.5
        )

        defer {
            _ = database.deleteEntry(id: inDayId)
            _ = database.deleteEntry(id: nextDayId)
        }

        _ = database.createEntry(inDayEntry)
        _ = database.createEntry(nextDayEntry)

        let results = database.getEntriesForDate(queryDate)
        let resultIds = Set(results.map(\.id))

        #expect(resultIds.contains(inDayId))
        #expect(resultIds.contains(nextDayId) == false)
    }

    @Test("getAllCategories returns deterministic ordered results")
    func getAllCategoriesOrderIsStable() {
        let prefix = "test-\(UUID().uuidString)"
        let categories = [
            "\(prefix)-Zulu",
            "\(prefix)-Alpha",
            "\(prefix)-Echo"
        ]

        let entryIds = categories.enumerated().map { index, category in
            WeeklyLogEntry(
                id: UUID(),
                date: Date().addingTimeInterval(TimeInterval(index * 60)),
                category: category,
                task: "Order test \(index)",
                timeSpent: 0.25
            ).id
        }

        let entries = categories.enumerated().map { index, category in
            WeeklyLogEntry(
                id: entryIds[index],
                date: Date().addingTimeInterval(TimeInterval(index * 60)),
                category: category,
                task: "Order test \(index)",
                timeSpent: 0.25
            )
        }

        defer {
            for id in entryIds {
                _ = database.deleteEntry(id: id)
            }
        }

        for entry in entries {
            _ = database.createEntry(entry)
        }

        let ordered = database.getAllCategories().filter { $0.hasPrefix(prefix) }
        #expect(ordered == ordered.sorted())
    }
}
