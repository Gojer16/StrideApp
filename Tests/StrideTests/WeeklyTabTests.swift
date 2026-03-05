import Testing
import Foundation
@testable import Stride

@Suite("Weekly Tab Tests")
struct WeeklyTabTests {
    final class TestDatabaseHarness {
        let path: String
        let database: UsageDatabase
        
        init() {
            path = FileManager.default.temporaryDirectory
                .appendingPathComponent("stride-week-tests-\(UUID().uuidString).sqlite")
                .path
            database = UsageDatabase.makeTestingDatabase(atPath: path)
        }
        
        deinit {
            database.waitForPendingWrites()
            let fileManager = FileManager.default
            try? fileManager.removeItem(atPath: path)
            try? fileManager.removeItem(atPath: "\(path)-shm")
            try? fileManager.removeItem(atPath: "\(path)-wal")
        }
    }
    
    @Test("Week dates include Monday through reference day only")
    func weekDatesThroughToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        
        var referenceComponents = DateComponents()
        referenceComponents.year = 2025
        referenceComponents.month = 11
        referenceComponents.day = 5
        referenceComponents.hour = 12
        let reference = calendar.date(from: referenceComponents)!
        let dates = WeeklyView.weekDatesThroughToday(referenceDate: reference, calendar: calendar)
        
        #expect(dates.count == 3)
        #expect(calendar.component(.weekday, from: dates.first!) == 2) // Monday
        #expect(calendar.isDate(dates.last!, inSameDayAs: calendar.startOfDay(for: reference)))
    }
    
    @Test("Live session overlay augments matching day without DB roundtrip")
    func mergePersistedWeekDataWithLiveSession() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        
        let monday = Date(timeIntervalSince1970: 1_762_012_800)
        let tuesday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: monday))!
        let persisted: [(date: Date, time: TimeInterval)] = [
            (calendar.startOfDay(for: monday), 120),
            (tuesday, 240)
        ]
        
        let snapshot = AppState.LiveSessionSnapshot(
            appName: "Xcode",
            windowTitle: "WeeklyView.swift",
            startTime: tuesday.addingTimeInterval(3600),
            activeDuration: 30,
            passiveDuration: 0
        )
        
        let merged = WeeklyView.mergePersistedWeekData(persisted, with: snapshot, calendar: calendar)
        
        #expect(merged.count == 2)
        #expect(merged[0].time == 120)
        #expect(merged[1].time == 270)
    }
    
    @Test("Batched getTimes aggregates selected week dates")
    func batchedGetTimesForDates() {
        let harness = TestDatabaseHarness()
        let database = harness.database
        let calendar = Calendar.current
        
        let monday = Date().startOfWeek
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        
        _ = database.seedSessionForTesting(
            appName: "Xcode",
            windowTitle: "Feature A",
            startTime: monday.addingTimeInterval(3600),
            duration: 120
        )
        
        _ = database.seedSessionForTesting(
            appName: "Safari",
            windowTitle: "Docs",
            startTime: tuesday.addingTimeInterval(5400),
            duration: 180
        )
        
        database.waitForPendingWrites()
        
        let dates = [monday, tuesday]
        let totals = database.getTimes(for: dates)
        
        #expect((totals[calendar.startOfDay(for: monday)] ?? 0) >= 120)
        #expect((totals[calendar.startOfDay(for: tuesday)] ?? 0) >= 180)
    }
}
