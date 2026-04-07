import Testing
import Foundation
@testable import Stride

@Suite("Today Tab Integration Tests")
struct TodayTabIntegrationTests {
    final class TestDatabaseHarness {
        let path: String
        let database: UsageDatabase
        
        init() {
            path = FileManager.default.temporaryDirectory
                .appendingPathComponent("stride-today-tests-\(UUID().uuidString).sqlite")
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
    
    @Test("Today stats persist completed sessions and invalidate cache")
    func todayStatsPersistCompletedSessions() {
        let harness = TestDatabaseHarness()
        let database = harness.database
        let sessionManager = SessionManager(database: database)
        
        sessionManager.startNewSession(appName: "Xcode", windowTitle: "StrideApp.swift")
        usleep(80_000)
        sessionManager.pauseSession()
        usleep(30_000)
        sessionManager.resumeSession()
        usleep(60_000)
        sessionManager.endCurrentSession()
        database.waitForPendingWrites()
        
        guard let app = database.getApplication(name: "Xcode") else {
            Issue.record("Expected Xcode app to be persisted")
            return
        }
        
        let firstStats = database.getTodayStats()
        guard let firstSession = firstStats[app.id.uuidString] else {
            Issue.record("Expected persisted today stats for Xcode")
            return
        }
        
        #expect(firstSession.active > 0.05)
        #expect(firstSession.passive > 0.02)
        
        sessionManager.startNewSession(appName: "Xcode", windowTitle: "TodayView.swift")
        usleep(60_000)
        sessionManager.endCurrentSession()
        database.waitForPendingWrites()
        
        let secondStats = database.getTodayStats()
        guard let secondSession = secondStats[app.id.uuidString] else {
            Issue.record("Expected updated today stats after second session")
            return
        }
        
        #expect(secondSession.active > firstSession.active)
        #expect(secondSession.passive >= firstSession.passive)
        
        let hourlyUsage = database.getHourlyUsage(for: app.id.uuidString)
        #expect(hourlyUsage.count == 24)
        #expect(hourlyUsage.contains { $0 > 0 })
    }
    
    @Test("Today browser domains aggregate persisted browser sessions")
    func todayBrowserDomainsAggregateSessions() {
        let harness = TestDatabaseHarness()
        let database = harness.database
        let sessionManager = SessionManager(database: database)
        
        sessionManager.startNewSession(appName: "Google Chrome", windowTitle: "GitHub - apple/swift")
        usleep(60_000)
        sessionManager.endCurrentSession()
        database.waitForPendingWrites()
        
        sessionManager.startNewSession(appName: "Google Chrome", windowTitle: "https://github.com/openai/openai")
        usleep(60_000)
        sessionManager.endCurrentSession()
        database.waitForPendingWrites()
        
        let browserDomains = database.getTodayBrowserDomains()
        let github = browserDomains.first { $0.domain == "github.com" }
        
        #expect(browserDomains.count == 1)
        #expect(github != nil)
        #expect((github?.activeTime ?? 0) > 0.08)
        #expect((github?.passiveTime ?? 0) == 0)
        
        guard let browserApp = database.getApplication(name: "Google Chrome") else {
            Issue.record("Expected browser app to be created")
            return
        }
        
        let todayStats = database.getTodayStats()
        #expect(todayStats[browserApp.id.uuidString] != nil)
    }
}
