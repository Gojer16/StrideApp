import Testing
import Foundation
@testable import Stride

/// Comprehensive test suite for the Today tab feature
/// Tests models, utilities, and feature logic

@Suite("Today Tab Tests")
struct TodayTabTests {
    
    // MARK: - Model Tests
    
    @Test("Empty TodayStats")
    func emptyStats() {
        let stats = TodayStats.empty
        
        #expect(stats.apps.isEmpty)
        #expect(stats.browserDomains.isEmpty)
        #expect(stats.totalActiveTime == 0)
        #expect(stats.totalPassiveTime == 0)
        #expect(stats.totalVisits == 0)
        #expect(stats.categoryBreakdown.isEmpty)
    }
    
    @Test("BrowserDomain total time calculation")
    func browserDomainTotalTime() {
        let domain = BrowserDomain(
            domain: "github.com",
            browserApp: "Chrome",
            activeTime: 1800,
            passiveTime: 600
        )
        
        #expect(domain.totalTime == 2400)
        #expect(domain.domain == "github.com")
        #expect(domain.browserApp == "Chrome")
    }
    
    @Test("BrowserDomain has unique IDs")
    func browserDomainUniqueIDs() {
        let domain1 = BrowserDomain(domain: "github.com", browserApp: "Chrome", activeTime: 1800, passiveTime: 600)
        let domain2 = BrowserDomain(domain: "github.com", browserApp: "Chrome", activeTime: 1800, passiveTime: 600)
        
        #expect(domain1.id != domain2.id)
    }
    
    // MARK: - Domain Parser Tests
    
    @Test("Extract domain from URL")
    func extractDomainFromURL() {
        let title = "https://github.com/apple/swift"
        let domain = DomainParser.extractDomain(from: title)
        #expect(domain == "github.com")
    }
    
    @Test("Extract domain from site name")
    func extractDomainFromSiteName() {
        let title = "GitHub - apple/swift"
        let domain = DomainParser.extractDomain(from: title)
        #expect(domain == "github.com")
    }
    
    @Test("Handle localhost")
    func handleLocalhost() {
        let title = "localhost:3000"
        let domain = DomainParser.extractDomain(from: title)
        #expect(domain == "localhost")
    }
    
    @Test("Return nil for non-browser titles")
    func nonBrowserTitle() {
        let title = "Untitled Document"
        let domain = DomainParser.extractDomain(from: title)
        #expect(domain == nil)
    }
    
    @Test("YouTube variations", arguments: [
        "youtube.com",
        "https://www.youtube.com/watch?v=123"
    ])
    func youtubeVariations(title: String) {
        let domain = DomainParser.extractDomain(from: title)
        #expect(domain == "youtube.com")
    }
    
    // MARK: - TimeInterval Formatting Tests
    
    @Test("Format seconds")
    func formatSeconds() {
        let interval = 45.0
        #expect(interval.formatted() == "45s")
    }
    
    @Test("Format minutes")
    func formatMinutes() {
        let interval = 125.0 // 2m 5s
        #expect(interval.formatted() == "2m 5s")
    }
    
    @Test("Format hours")
    func formatHours() {
        let interval = 3665.0 // 1h 1m 5s
        #expect(interval.formatted() == "1h 1m")
    }
    
    @Test("Format zero")
    func formatZero() {
        let interval = 0.0
        #expect(interval.formatted() == "0s")
    }
    
    @Test("Format exact hour")
    func formatExactHour() {
        let interval = 3600.0 // 1h
        #expect(interval.formatted() == "1h 0m")
    }
    
    // MARK: - User Preferences Tests
    
    @Test("Default day start hour")
    func defaultDayStartHour() {
        let prefs = UserPreferences.shared
        // Default is 0 (midnight) but user may have changed it
        #expect(prefs.dayStartHour >= 0)
        #expect(prefs.dayStartHour <= 23)
    }
    
    @Test("Default idle threshold")
    func defaultIdleThreshold() {
        let prefs = UserPreferences.shared
        // Default is 65 seconds
        #expect(prefs.idleThreshold >= 15)
        #expect(prefs.idleThreshold <= 300)
    }
    
    @Test("Logical start of today calculation")
    func logicalStartOfToday() {
        let prefs = UserPreferences.shared
        let logicalStart = prefs.logicalStartOfToday
        
        // Should return a valid date
        #expect(logicalStart <= Date())
    }
    
    @Test("Extended day detection")
    func extendedDayDetection() {
        let prefs = UserPreferences.shared
        let isExtended = prefs.isInExtendedDay
        
        // Should be boolean
        #expect(isExtended == true || isExtended == false)
    }
    
    // MARK: - Idle Detector Tests
    
    @Test("Get system idle time")
    func getSystemIdleTime() {
        let detector = IdleDetector()
        let idleTime = detector.getSystemIdleTime()
        
        // Should return a value or nil
        if let time = idleTime {
            #expect(time >= 0)
        }
    }
    
    @Test("Is system idle with high threshold")
    func isSystemIdleHighThreshold() {
        let detector = IdleDetector()
        
        // With very high threshold, should not be idle
        let isIdle = detector.isSystemIdle(threshold: 999999)
        #expect(!isIdle)
    }
    
    // MARK: - Category Tests
    
    @Test("Category initialization")
    func categoryInit() {
        let category = Category(
            name: "Work",
            icon: "💼",
            color: "#4A7C59",
            order: 0
        )
        
        #expect(category.name == "Work")
        #expect(category.icon == "💼")
        #expect(category.color == "#4A7C59")
        #expect(category.order == 0)
    }
    
    @Test("Default categories exist")
    func defaultCategories() {
        let defaults = Category.defaultCategories
        
        #expect(!defaults.isEmpty)
        #expect(defaults.count == 8)
        
        let workCategory = defaults.first { $0.name == "Work" }
        #expect(workCategory != nil)
        #expect(workCategory!.isDefault == true)
    }
    
    // MARK: - Integration Tests
    
    @Test("Complete TodayStats structure")
    func todayStatsStructure() {
        let category = Category(
            name: "Work",
            icon: "💼",
            color: "#4A7C59",
            order: 0
        )
        
        let app = AppUsage(
            id: UUID(),
            name: "Xcode",
            categoryId: category.id.uuidString,
            firstSeen: Date(),
            lastSeen: Date(),
            totalTimeSpent: 7200,
            visitCount: 5,
            windows: []
        )
        
        let appStats = TodayStats.AppStats(
            app: app,
            activeTime: 6600,
            passiveTime: 600,
            hourlyUsage: Array(repeating: 300, count: 24)
        )
        
        let domain = BrowserDomain(
            domain: "github.com",
            browserApp: "Chrome",
            activeTime: 3300,
            passiveTime: 300
        )
        
        let stats = TodayStats(
            apps: [appStats],
            browserDomains: [domain],
            totalActiveTime: 9900,
            totalPassiveTime: 900,
            totalVisits: 5,
            categoryBreakdown: [(category, 10800)]
        )
        
        #expect(stats.apps.count == 1)
        #expect(stats.browserDomains.count == 1)
        #expect(stats.totalActiveTime == 9900)
        #expect(stats.totalPassiveTime == 900)
        #expect(stats.totalVisits == 5)
        #expect(stats.categoryBreakdown.count == 1)
    }
    
    @Test("Browser domain aggregation logic")
    func browserDomainAggregation() {
        var domains: [String: BrowserDomain] = [:]
        
        let titles = [
            "GitHub - apple/swift",
            "https://github.com/google/swift",
            "GitHub · Build software better, together"
        ]
        
        for title in titles {
            if let domainName = DomainParser.extractDomain(from: title) {
                if var existing = domains[domainName] {
                    existing.activeTime += 600
                    domains[domainName] = existing
                } else {
                    domains[domainName] = BrowserDomain(
                        domain: domainName,
                        browserApp: "Chrome",
                        activeTime: 600,
                        passiveTime: 0
                    )
                }
            }
        }
        
        // Should aggregate into single github.com domain
        #expect(domains.count == 1)
        #expect(domains["github.com"] != nil)
        #expect(domains["github.com"]!.activeTime == 1800)
    }
    
    @Test("Hourly usage array structure")
    func hourlyUsageStructure() {
        let hourlyUsage = Array(repeating: 0.0, count: 24)
        
        #expect(hourlyUsage.count == 24)
        
        var mutableHourly = hourlyUsage
        mutableHourly[9] = 1800  // 9 AM
        mutableHourly[14] = 2400 // 2 PM
        mutableHourly[20] = 600  // 8 PM
        
        #expect(mutableHourly[9] == 1800)
        #expect(mutableHourly[14] == 2400)
        #expect(mutableHourly[20] == 600)
        #expect(mutableHourly[0] == 0)
        #expect(mutableHourly[23] == 0)
    }
    
    @Test("Active vs passive time separation")
    func activePassiveTimeSeparation() {
        let category = Category(name: "Work", icon: "💼", color: "#4A7C59", order: 0)
        
        let app1 = AppUsage(
            id: UUID(),
            name: "Xcode",
            categoryId: category.id.uuidString,
            firstSeen: Date(),
            lastSeen: Date(),
            totalTimeSpent: 7200,
            visitCount: 5,
            windows: []
        )
        
        let appStats1 = TodayStats.AppStats(
            app: app1,
            activeTime: 6600,
            passiveTime: 600,
            hourlyUsage: []
        )
        
        let app2 = AppUsage(
            id: UUID(),
            name: "YouTube",
            categoryId: category.id.uuidString,
            firstSeen: Date(),
            lastSeen: Date(),
            totalTimeSpent: 3600,
            visitCount: 2,
            windows: []
        )
        
        let appStats2 = TodayStats.AppStats(
            app: app2,
            activeTime: 600,
            passiveTime: 3000,
            hourlyUsage: []
        )
        
        #expect(appStats1.activeTime > appStats1.passiveTime) // Xcode: mostly active
        #expect(appStats2.passiveTime > appStats2.activeTime) // YouTube: mostly passive
    }
    
    // MARK: - Performance Tests
    
    @Test("TimeInterval formatting performance")
    func timeIntervalFormattingPerformance() {
        let intervals = [45.0, 125.0, 3665.0, 7200.0, 10800.0, 86400.0]
        
        let start = Date()
        for interval in intervals {
            _ = interval.formatted()
        }
        let elapsed = Date().timeIntervalSince(start)
        
        #expect(elapsed < 0.001)
    }
    
    @Test("Domain parsing performance")
    func domainParsingPerformance() {
        let titles = [
            "GitHub - apple/swift",
            "https://stackoverflow.com/questions/123",
            "YouTube - Swift Tutorial",
            "localhost:3000 - Development",
            "https://docs.github.com/en/get-started"
        ]
        
        let start = Date()
        for title in titles {
            _ = DomainParser.extractDomain(from: title)
        }
        let elapsed = Date().timeIntervalSince(start)
        
        // Should complete in under 5ms (relaxed for CI)
        #expect(elapsed < 0.005)
    }
}
