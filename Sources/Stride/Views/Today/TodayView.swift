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
 * 1. Summary Grid: Displays three primary KPIs (Active Time, App Switches, Total Apps).
 * 2. Category Mix: A visual donut chart showing the distribution of time across labels.
 * 3. Top Utilization: A ranked list of the most used applications for the day.
 * 
 * **Design Philosophy:**
 * - Clean "Warm Paper" background.
 * - Glassmorphism for data containers.
 * - Staggered spring animations for an energetic, premium feel.
 */
struct TodayView: View {
    @State private var applications: [AppUsage] = []
    @State private var totalTime: TimeInterval = 0
    @State private var totalVisits: Int = 0
    @State private var categoryBreakdown: [(category: Category, time: TimeInterval)] = []
    
    /// Controls the staggered entrance of UI components
    @State private var isLoaded = false
    
    // MARK: - Design System Constants
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(hex: "#4A7C59") // Stride Moss
    
    private var topApps: [AppUsage] {
        Array(applications.prefix(5))
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // MARK: 1. Editorial Header
                    headerSection
                        .padding(.top, 24)
                    
                    // MARK: 2. Summary KPI Grid
                    metricsGrid
                    
                    if !applications.isEmpty {
                        // MARK: 3. Distribution & Rankings
                        HStack(alignment: .top, spacing: 32) {
                            categoryDistributionSection
                                .frame(maxWidth: .infinity)
                            
                            topAppsSection
                                .frame(width: 380)
                        }
                    } else {
                        // Shown when no data has been tracked for the day
                        emptyStateView
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Fetch fresh data and trigger entrance animations
            loadData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isLoaded = true
            }
        }
    }
    
    // MARK: - Sections
    
    /**
     * Large typographic header showing the current date and primary view title.
     */
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate())
                .font(.system(size: 12, weight: .black))
                .foregroundColor(accentColor)
                .tracking(2)
                .textCase(.uppercase)
            
            Text("Day Summary")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
    }
    
    /**
     * A row of cards summarizing the day's core metrics.
     */
    private var metricsGrid: some View {
        HStack(spacing: 20) {
            SummaryMetricCard(
                title: "Active Time",
                value: formattedTotalTime(),
                icon: "clock.fill",
                color: accentColor,
                delay: 0.1,
                isLoaded: isLoaded
            )
            
            SummaryMetricCard(
                title: "App Switches",
                value: "\(totalVisits)",
                icon: "arrow.left.arrow.right",
                color: Color(hex: "#C75B39"), // Stride Terracotta
                delay: 0.2,
                isLoaded: isLoaded
            )
            
            SummaryMetricCard(
                title: "Total Apps",
                value: "\(applications.count)",
                icon: "square.grid.2x2.fill",
                color: Color(hex: "#5B7C8C"), // Stride Slate
                delay: 0.3,
                isLoaded: isLoaded
            )
        }
    }
    
    /**
     * A "Glass" container holding the donut chart and legend for category breakdown.
     */
    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CATEGORY MIX")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            HStack(spacing: 32) {
                // The visual donut chart
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.03), lineWidth: 28)
                    
                    ForEach(0..<min(categoryBreakdown.count, 5), id: \.self) { index in
                        Circle()
                            .trim(from: categoryStartAngle(for: index), to: categoryEndAngle(for: index))
                            .stroke(
                                Color(hex: categoryBreakdown[index].category.color),
                                style: StrokeStyle(lineWidth: 28, lineCap: .butt)
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
                .frame(width: 140, height: 140)
                
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
            .padding(32)
            .background(glassMaterial)
        }
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 30)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.4), value: isLoaded)
    }
    
    /**
     * A vertical list of the most utilized applications for today.
     */
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TOP UTILIZATION")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            VStack(spacing: 12) {
                ForEach(Array(topApps.enumerated()), id: \.element.id) { index, app in
                    let appTime = UsageDatabase.shared.getTodayTime(for: app.id.uuidString)
                    let percentage = totalTime > 0 ? appTime / totalTime : 0
                    
                    TodayAppRow(
                        app: app,
                        todayTime: appTime,
                        percentage: percentage,
                        rank: index + 1
                    )
                }
            }
        }
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 30)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.5), value: isLoaded)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 48))
                .foregroundColor(accentColor.opacity(0.2))
            Text("No activity recorded yet today.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(secondaryText)
        }
        .padding(.vertical, 100)
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
    
    /**
     * Fetches today's applications and pre-calculates the totals and breakdowns.
     */
    private func loadData() {
        let allApps = UsageDatabase.shared.getAllApplications()
        
        // Filter out apps not used today and sort by duration
        applications = allApps.filter { UsageDatabase.shared.getTodayTime(for: $0.id.uuidString) > 0 }
        .sorted {
            UsageDatabase.shared.getTodayTime(for: $0.id.uuidString) >
            UsageDatabase.shared.getTodayTime(for: $1.id.uuidString)
        }
        
        totalTime = applications.reduce(0) {
            $0 + UsageDatabase.shared.getTodayTime(for: $1.id.uuidString)
        }
        
        // Note: Currently returns cumulative visits, could be optimized for "today-only" visits
        totalVisits = applications.reduce(0) {
            $0 + $1.visitCount
        }
        
        // Calculate category percentage distribution
        let categories = UsageDatabase.shared.getAllCategories()
        categoryBreakdown = categories.compactMap { category in
            let categoryApps = applications.filter { $0.categoryId == category.id.uuidString.lowercased() }
            let categoryTime = categoryApps.reduce(0) {
                $0 + UsageDatabase.shared.getTodayTime(for: $1.id.uuidString)
            }
            return categoryTime > 0 ? (category, categoryTime) : nil
        }.sorted { $0.time > $1.time }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private func formattedTotalTime() -> String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                    .tracking(1)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 15, x: 0, y: 5)
        )
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
        .animation(DesignSystem.Animation.entrance.spring.delay(delay), value: isLoaded)
    }
}
