import SwiftUI

/**
 * TodayView - An editorial summary of the user's digital footprint for the current day.
 * 
 * **Role in Stride:**
 * This view serves as the "Daily Mirror," providing a high-level summary of how 
 * time was spent since midnight. It balances data density with an editorial 
 * aesthetic to make usage statistics feel like a professional report.
 * 
 * **Key Features:**
 * 1. Summary Grid: Displays primary KPIs (Active Time, Passive Time, Focused App, Total Apps).
 * 2. Category Mix: A visual donut chart showing the distribution of time across labels.
 * 3. Top Utilization: A ranked list of the most used applications for the day.
 * 
 * **Design Philosophy:**
 * - Clean "Warm Paper" background.
 * - Glassmorphism for data containers.
 * - Staggered spring animations for an energetic, premium feel.
 */
struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @State private var todayStats: TodayStats = .empty
    @State private var isFirstLoad: Bool = true
    
    /// Controls the staggered entrance of UI components
    @State private var isLoaded = false
    
    // Computed properties for backward compatibility
    private var applications: [TodayStats.AppStats] {
        todayStats.apps
    }
    
    private var totalTime: TimeInterval {
        todayStats.totalActiveTime
    }
    
    private var totalPassiveTime: TimeInterval {
        todayStats.totalPassiveTime
    }
    
    private var focusedAppName: String {
        todayStats.focusedAppName ?? "No app yet"
    }
    
    private var totalTrackedApps: Int {
        todayStats.totalTrackedApps
    }
    
    private var categoryBreakdown: [(category: Category, time: TimeInterval)] {
        todayStats.categoryBreakdown
    }
    
    private var topApps: [TodayStats.AppStats] {
        Array(applications.prefix(5))
    }
    
    private var hasTrackedContent: Bool {
        totalTrackedApps > 0 || !todayStats.browserDomains.isEmpty
    }
    
    // MARK: - Design System Constants
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(hex: "#4A7C59") // Stride Moss
    private let bentoTileHeight: CGFloat = 300
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // MARK: 1. Editorial Header
                    headerSection
                        .padding(.top, 16)
                    
                    // MARK: 2. Summary KPI Grid
                    metricsGrid
                    
                    if isFirstLoad {
                        loadingStateView
                    } else if hasTrackedContent {
                        compactDashboardSection
                    } else {
                        // Shown when no data has been tracked for the day
                        emptyStateView
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            loadData()
            withAnimation(DesignSystem.Animation.entrance.spring) {
                isLoaded = true
            }
        }
        .onChange(of: appState.elapsedTime) { _, _ in
            loadData()
        }
        .onChange(of: appState.activeAppName) { _, _ in
            loadData()
        }
    }
    
    // MARK: - Sections
    
    /**
     * Large typographic header showing the current date and primary view title.
     */
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(formattedDate())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(accentColor)
                    .tracking(2)
                    .textCase(.uppercase)
                
                // Extended mode badge
                if UserPreferences.shared.isInExtendedDay {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 8))
                        Text("LATE NIGHT")
                            .font(.system(size: 8, weight: .black))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#7A6B8A"))
                    )
                }
            }
            
            Text("Day Summary")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundColor(textColor)
            
            Text(headerSummaryCopy)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
    }
    
    /**
     * A row of cards summarizing the day's core metrics.
     */
    private var metricsGrid: some View {
        HStack(spacing: 14) {
            SummaryMetricCard(
                title: "Active Time",
                value: isFirstLoad ? "..." : formattedTotalTime(),
                icon: "clock.fill",
                color: accentColor,
                delay: 0.1,
                isLoaded: isLoaded,
                isLoading: isFirstLoad
            )
            
            SummaryMetricCard(
                title: "Idle Time",
                value: isFirstLoad ? "..." : formattedPassiveTime(),
                icon: "pause.circle.fill",
                color: Color(hex: "#5B7C8C").opacity(0.7), // Stride Slate (muted)
                delay: 0.15,
                isLoaded: isLoaded,
                isLoading: isFirstLoad
            )
            
            SummaryMetricCard(
                title: "Focused App",
                value: isFirstLoad ? "Loading" : focusedAppName,
                icon: "scope",
                color: Color(hex: "#C75B39"), // Stride Terracotta
                delay: 0.2,
                isLoaded: isLoaded,
                isLoading: isFirstLoad
            )
            
            SummaryMetricCard(
                title: "Total Apps",
                value: isFirstLoad ? "..." : "\(totalTrackedApps)",
                icon: "square.grid.2x2.fill",
                color: Color(hex: "#5B7C8C"), // Stride Slate
                delay: 0.3,
                isLoaded: isLoaded,
                isLoading: isFirstLoad
            )
        }
    }
    
    private var compactDashboardSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ],
            spacing: 20
        ) {
            bentoTile(delay: 0.3) {
                categoryDistributionSection
            }
            
            if !applications.isEmpty {
                bentoTile(delay: 0.35) {
                    topAppsSection
                }
            }
            
            bentoTile(delay: 0.4) {
                todayAtAGlanceSection
            }
            
            if !todayStats.browserDomains.isEmpty {
                bentoTile(delay: 0.45) {
                    webActivitySection
                }
            }
        }
    }
    
    /**
     * A "Glass" container holding the donut chart and legend for category breakdown.
     */
    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TIME BY CATEGORY")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            HStack(spacing: 24) {
                // The visual donut chart
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.03), lineWidth: 24)
                    
                    ForEach(0..<min(categoryBreakdown.count, 5), id: \.self) { index in
                        Circle()
                            .trim(from: categoryStartAngle(for: index), to: categoryEndAngle(for: index))
                            .stroke(
                                Color(hex: categoryBreakdown[index].category.color),
                                style: StrokeStyle(lineWidth: 24, lineCap: .butt)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    
                    VStack(spacing: 0) {
                        Text("\(categoryBreakdown.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("LABELS")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(secondaryText)
                    }
                }
                .frame(width: 120, height: 120)
                
                // Detailed Legend
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(categoryBreakdown.prefix(5), id: \.category.id) { item in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: item.category.color))
                                .frame(width: 12, height: 12)
                            
                            Text(item.category.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(textColor)
                            
                            Spacer()
                            
                            Text(item.time.formatted())
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(secondaryText)
                        }
                    }
                }
            }
        }
    }
    
    private var todayAtAGlanceSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("AT A GLANCE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            HStack(alignment: .top, spacing: 14) {
                CompactInsightTile(
                    eyebrow: "Top Category",
                    title: topCategoryTitle,
                    detail: topCategoryDetail,
                    tint: topCategoryColor
                )
                
                CompactInsightTile(
                    eyebrow: "Focused App",
                    title: focusedAppDisplayName,
                    detail: focusedAppDetail,
                    tint: Color(hex: "#C75B39")
                )
                
                CompactInsightTile(
                    eyebrow: "Top Site",
                    title: topSiteTitle,
                    detail: topSiteDetail,
                    tint: topSiteColor
                )
            }
        }
    }
    
    /**
     * Web Activity section showing top domains visited in browsers.
     */
    private var webActivitySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TOP SITES")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            VStack(spacing: 12) {
                ForEach(Array(todayStats.browserDomains.prefix(3)), id: \.domain) { domain in
                    BrowserDomainRow(domain: domain, totalTime: totalTime)
                }
            }
        }
    }
    
    /**
     * A vertical list of the most utilized applications for today.
     */
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TOP APPS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            VStack(spacing: 12) {
                ForEach(Array(topApps.prefix(2).enumerated()), id: \.element.app.id) { index, appStats in
                    let percentage = totalTime > 0 ? appStats.activeTime / totalTime : 0
                    
                    TodayAppRow(
                        app: appStats.app,
                        todayTime: appStats.activeTime,
                        percentage: percentage,
                        rank: index + 1,
                        hourlyUsage: appStats.hourlyUsage
                    )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Image(systemName: "sun.haze.fill")
                .font(.system(size: 48))
                .foregroundColor(accentColor.opacity(0.25))
            Text("Today is still quiet.")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(textColor)
            Text("Your summary will start filling in automatically as you move through apps and websites.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(.vertical, 72)
        .frame(maxWidth: .infinity)
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
                .tint(accentColor)
            Text("Pulling in today’s activity…")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(textColor)
            Text("Your summary is loading and will keep itself up to date while you work.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(.vertical, 72)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    
    private var glassMaterial: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Color.white.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 10)
    }
    
    private func bentoTile<Content: View>(delay: Double, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: bentoTileHeight, maxHeight: bentoTileHeight, alignment: .topLeading)
            .background(glassMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .opacity(isLoaded ? 1 : 0)
            .offset(y: isLoaded ? 0 : 30)
            .animation(DesignSystem.Animation.entrance.spring.delay(delay), value: isLoaded)
    }
    
    private var headerSummaryCopy: String {
        if isFirstLoad {
            return "Pulling together today’s pace, focus, and category mix."
        }
        
        if !hasTrackedContent {
            return "A calm start. Your day will take shape here as activity comes in."
        }
        
        if applications.isEmpty && !todayStats.browserDomains.isEmpty {
            return "A browser-led day so far, with web activity carrying most of the signal."
        }
        
        if totalTrackedApps == 1 {
            return "\(formattedTotalTime()) of active time centered on one app so far."
        }
        
        return "\(formattedTotalTime()) of active time across \(totalTrackedApps) apps so far."
    }
    
    private var focusedAppDisplayName: String {
        if isFirstLoad {
            return "Loading"
        }
        return todayStats.focusedAppName ?? "Warming up"
    }
    
    private var focusedAppDetail: String {
        guard let focusedApp = applications.first else {
            return "Waiting for a clear leader"
        }
        return "\(focusedApp.activeTime.formatted()) today"
    }
    
    private var topCategoryTitle: String {
        categoryBreakdown.first?.category.name ?? "No category yet"
    }
    
    private var topCategoryDetail: String {
        guard let topCategory = categoryBreakdown.first else {
            return "Categories will appear as activity lands"
        }
        return "\(topCategory.time.formatted()) logged"
    }
    
    private var topCategoryColor: Color {
        guard let topCategory = categoryBreakdown.first else {
            return accentColor
        }
        return Color(hex: topCategory.category.color)
    }
    
    private var topSiteTitle: String {
        todayStats.browserDomains.first?.displayName ?? "No sites yet"
    }
    
    private var topSiteDetail: String {
        guard let domain = todayStats.browserDomains.first else {
            return "Web activity will show up here"
        }
        return "\(domain.activeTime.formatted()) across \(todayStats.browserDomains.count) sites"
    }
    
    private var topSiteColor: Color {
        guard let domain = todayStats.browserDomains.first else {
            return Color(hex: "#5B7C8C")
        }
        return Color(hex: domain.categoryColor)
    }
    
    /**
     * Fetches today's applications and pre-calculates the totals and breakdowns.
     */
    /**
     Fetches today's data in the background and updates UI on main thread.
     
     **Performance Optimization:**
     - Uses single batch query instead of N individual queries
     - Runs on background thread to avoid blocking UI
     - Shows cached data immediately (from previous load)
     - Updates smoothly when fresh data arrives
     */
    private func loadData() {
        let liveSession = appState.liveSessionSnapshot
        Task {
            let stats = await loadDataAsync(liveSession: liveSession)
            await MainActor.run {
                self.todayStats = stats
                self.isFirstLoad = false
            }
        }
    }
    
    private func loadDataAsync(liveSession: AppState.LiveSessionSnapshot?) async -> TodayStats {
        // Run database queries on background thread
        return await Task.detached(priority: .userInitiated) {
            let database = UsageDatabase.shared
            
            // Single batch query - gets all today's data at once
            let todayStatsMap = database.getTodayStats()
            var browserDomains = database.getTodayBrowserDomains()
            
            // Get all apps and filter/sort using cached stats
            let allApps = database.getAllApplications()
            var allAppsWithStats = allApps.compactMap { app -> TodayStats.AppStats? in
                guard let stats = todayStatsMap[app.id.uuidString] else { return nil }
                guard stats.active > 0 || stats.passive > 0 else { return nil }

                return TodayStats.AppStats(
                    app: app,
                    activeTime: stats.active,
                    passiveTime: stats.passive,
                    hourlyUsage: []
                )
            }
            
            var unassignedBrowserActive: TimeInterval = 0
            var unassignedBrowserPassive: TimeInterval = 0
            
            if let liveSession,
               let liveApp = database.getApplication(name: liveSession.appName),
               liveSession.activeDuration > 0 || liveSession.passiveDuration > 0 {
                let overlay = TodayStats.AppStats(
                    app: liveApp,
                    activeTime: liveSession.activeDuration,
                    passiveTime: liveSession.passiveDuration,
                    hourlyUsage: []
                )
                
                if let existingIndex = allAppsWithStats.firstIndex(where: { $0.app.id == liveApp.id }) {
                    let existing = allAppsWithStats[existingIndex]
                    allAppsWithStats[existingIndex] = TodayStats.AppStats(
                        app: existing.app,
                        activeTime: existing.activeTime + overlay.activeTime,
                        passiveTime: existing.passiveTime + overlay.passiveTime,
                        hourlyUsage: existing.hourlyUsage
                    )
                } else {
                    allAppsWithStats.append(overlay)
                }
                
                if liveApp.isBrowser {
                    if let domainName = DomainParser.extractDomain(from: liveSession.windowTitle) {
                        if let domainIndex = browserDomains.firstIndex(where: { $0.domain.lowercased() == domainName.lowercased() }) {
                            browserDomains[domainIndex].activeTime += liveSession.activeDuration
                            browserDomains[domainIndex].passiveTime += liveSession.passiveDuration
                        } else {
                            browserDomains.append(
                                BrowserDomain(
                                    domain: domainName,
                                    browserApp: liveApp.name,
                                    activeTime: liveSession.activeDuration,
                                    passiveTime: liveSession.passiveDuration
                                )
                            )
                        }
                    } else {
                        unassignedBrowserActive += liveSession.activeDuration
                        unassignedBrowserPassive += liveSession.passiveDuration
                    }
                }
            }
            
            allAppsWithStats.sort { $0.activeTime > $1.activeTime }
            browserDomains.sort { $0.totalTime > $1.totalTime }
            
            let focusedAppName = allAppsWithStats.first?.app.name
            
            var appsWithStats = allAppsWithStats.filter { !$0.app.isBrowser }
            
            // Load hourly data for top 3 apps (for sparklines)
            if appsWithStats.count > 0 {
                for i in 0..<min(3, appsWithStats.count) {
                    let hourlyData = database.getHourlyUsage(for: appsWithStats[i].app.id.uuidString)
                    appsWithStats[i] = TodayStats.AppStats(
                        app: appsWithStats[i].app,
                        activeTime: appsWithStats[i].activeTime,
                        passiveTime: appsWithStats[i].passiveTime,
                        hourlyUsage: hourlyData
                    )
                }
            }
            
            // Calculate totals (including browser domains)
            let appActiveTime = appsWithStats.reduce(0) { $0 + $1.activeTime }
            let appPassiveTime = appsWithStats.reduce(0) { $0 + $1.passiveTime }
            let browserActiveTime = browserDomains.reduce(0) { $0 + $1.activeTime }
            let browserPassiveTime = browserDomains.reduce(0) { $0 + $1.passiveTime }
            
            let totalActive = appActiveTime + browserActiveTime + unassignedBrowserActive
            let totalPassive = appPassiveTime + browserPassiveTime + unassignedBrowserPassive
            // Calculate category breakdown across all tracked apps, including browsers.
            let categories = database.getAllCategories()
            let categoryBreakdown = categories.compactMap { category -> (category: Category, time: TimeInterval)? in
                let categoryApps = allAppsWithStats.filter { $0.app.categoryId == category.id.uuidString.lowercased() }
                let categoryTime = categoryApps.reduce(0) { $0 + $1.activeTime }
                return categoryTime > 0 ? (category, categoryTime) : nil
            }.sorted { $0.time > $1.time }
            
            return TodayStats(
                apps: appsWithStats,
                browserDomains: browserDomains,
                totalActiveTime: totalActive,
                totalPassiveTime: totalPassive,
                totalTrackedApps: allAppsWithStats.count,
                focusedAppName: focusedAppName,
                categoryBreakdown: categoryBreakdown
            )
        }.value
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        let logicalDate = UserPreferences.shared.logicalDate
        let dateString = formatter.string(from: logicalDate)
        
        // Add "(extended)" indicator if in extended day mode
        if UserPreferences.shared.isInExtendedDay {
            return "\(dateString) (extended)"
        }
        return dateString
    }
    
    private func formattedTotalTime() -> String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    private func formattedPassiveTime() -> String {
        let hours = Int(totalPassiveTime) / 3600
        let minutes = (Int(totalPassiveTime) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    private func categoryStartAngle(for index: Int) -> CGFloat {
        let total = categoryBreakdown.prefix(5).reduce(0) { $0 + $1.time }
        var start: CGFloat = 0
        for i in 0..<index {
            start += CGFloat(categoryBreakdown[i].time / total)
        }
        return start
    }
    
    private func categoryEndAngle(for index: Int) -> CGFloat {
        let total = categoryBreakdown.prefix(5).reduce(0) { $0 + $1.time }
        var end: CGFloat = 0
        for i in 0...index {
            end += CGFloat(categoryBreakdown[i].time / total)
        }
        return end
    }
}

/**
 * SummaryMetricCard - A high-polish metric component for the summary grid.
 * 
 * Features a large value display and a standardized layout for cross-view consistency.
 */
struct SummaryMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let delay: Double
    let isLoaded: Bool
    var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .redacted(reason: isLoading ? .placeholder : [])
                
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
                    .tracking(1)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(isLoading ? 0.72 : 1))
                .shadow(color: .black.opacity(0.03), radius: 15, x: 0, y: 5)
        )
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
        .animation(DesignSystem.Animation.entrance.spring.delay(delay), value: isLoaded)
    }
}

struct CompactInsightTile: View {
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 10, height: 10)
                Text(eyebrow.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.1)
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .lineLimit(2)
            
            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
}
