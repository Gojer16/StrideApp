import SwiftUI

/**
 * TodaySummaryWidget - Compact daily activity overview for the homepage.
 *
 * Surfaces key metrics from TodayView without requiring navigation:
 * - Active vs Idle time breakdown
 * - Top app and category
 * - App count and visit stats
 * - Mini visual progress indicator
 */
struct TodaySummaryWidget: View {
    @EnvironmentObject private var appState: AppState
    @State private var todayStats: TodayStats = .empty
    @State private var isLoading = true
    
    // MARK: - Design Constants
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(hex: "#4A7C59")
    private let terracottaColor = Color(hex: "#C75B39")
    
    private var hasData: Bool {
        todayStats.totalActiveTime > 0 || todayStats.totalTrackedApps > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                    
                    Text("Today")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                if UserPreferences.shared.isInExtendedDay {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 8))
                        Text("EXTENDED")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "#7A6B8A")))
                }
            }
            
            if isLoading {
                loadingPlaceholder
            } else if hasData {
                statsContent
            } else {
                emptyState
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .onAppear {
            loadData()
        }
        .onChange(of: appState.elapsedTime) { _, _ in
            loadData()
        }
        .onChange(of: appState.activeAppName) { _, _ in
            loadData()
        }
    }
    
    // MARK: - Content Views
    
    private var statsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time breakdown with mini bar
            timeBreakdownSection
            
            Divider()
                .opacity(0.5)
            
            // Quick stats row
            HStack(spacing: 16) {
                QuickStatItem(
                    icon: "app.fill",
                    value: "\(todayStats.totalTrackedApps)",
                    label: "Apps",
                    color: accentColor
                )
                
                if let topApp = todayStats.apps.first {
                    QuickStatItem(
                        icon: "star.fill",
                        value: topApp.app.name,
                        label: "Top App",
                        color: terracottaColor,
                        isCompact: true
                    )
                }
                
                if let topCategory = todayStats.categoryBreakdown.first {
                    QuickStatItem(
                        icon: "chart.pie.fill",
                        value: topCategory.category.name,
                        label: "Top Category",
                        color: Color(hex: topCategory.category.color),
                        isCompact: true
                    )
                }
            }
        }
    }
    
    private var timeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formattedActiveTime())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                Text("active")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)
                    .padding(.leading, 4)
                
                Spacer()
                
                if todayStats.totalPassiveTime > 0 {
                    Text("+ \(formattedPassiveTime()) idle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryText.opacity(0.7))
                }
            }
            
            // Progress bar showing active vs total
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 8)
                    
                    let totalTime = todayStats.totalActiveTime + todayStats.totalPassiveTime
                    let progress = totalTime > 0 ? todayStats.totalActiveTime / totalTime : 0
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)
            
            // Category mini pills
            if !todayStats.categoryBreakdown.isEmpty {
                HStack(spacing: 6) {
                    ForEach(todayStats.categoryBreakdown.prefix(3), id: \.category.id) { item in
                        let percentage = todayStats.totalActiveTime > 0 
                            ? Int((item.time / todayStats.totalActiveTime) * 100)
                            : 0
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: item.category.color))
                                .frame(width: 6, height: 6)
                            
                            Text("\(item.category.name) \(percentage)%")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(secondaryText)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: item.category.color).opacity(0.1))
                        )
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 14))
                    .foregroundColor(accentColor.opacity(0.6))
                
                Text("Today is just beginning")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
            }
            
            Text("Your activity will appear here as you use your apps")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.05))
                .frame(height: 32)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.05))
                .frame(height: 8)
        }
        .redacted(reason: .placeholder)
    }
    
    // MARK: - Helpers
    
    private func formattedActiveTime() -> String {
        let hours = Int(todayStats.totalActiveTime) / 3600
        let minutes = (Int(todayStats.totalActiveTime) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    private func formattedPassiveTime() -> String {
        let hours = Int(todayStats.totalPassiveTime) / 3600
        let minutes = (Int(todayStats.totalPassiveTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    private func loadData() {
        let liveSession = appState.liveSessionSnapshot
        Task {
            let stats = await loadDataAsync(liveSession: liveSession)
            await MainActor.run {
                self.todayStats = stats
                self.isLoading = false
            }
        }
    }
    
    private func loadDataAsync(liveSession: AppState.LiveSessionSnapshot?) async -> TodayStats {
        await Task.detached(priority: .userInitiated) {
            let database = UsageDatabase.shared
            let todayStatsMap = database.getTodayStats()
            var browserDomains = database.getTodayBrowserDomains()
            
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
            
            // Apply live session overlay
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
            }
            
            allAppsWithStats.sort { $0.activeTime > $1.activeTime }
            browserDomains.sort { $0.totalTime > $1.totalTime }
            
            let focusedAppName = allAppsWithStats.first?.app.name
            let appsWithStats = allAppsWithStats.filter { !$0.app.isBrowser }
            
            let appActiveTime = appsWithStats.reduce(0) { $0 + $1.activeTime }
            let appPassiveTime = appsWithStats.reduce(0) { $0 + $1.passiveTime }
            let browserActiveTime = browserDomains.reduce(0) { $0 + $1.activeTime }
            let browserPassiveTime = browserDomains.reduce(0) { $0 + $1.passiveTime }
            
            let totalActive = appActiveTime + browserActiveTime
            let totalPassive = appPassiveTime + browserPassiveTime
            
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
}

/**
 * QuickStatItem - Compact stat display for widget grids.
 */
private struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var isCompact: Bool = false
    
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.8)
                    .foregroundColor(secondaryText.opacity(0.8))
            }
            
            Text(value)
                .font(.system(size: isCompact ? 12 : 14, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
