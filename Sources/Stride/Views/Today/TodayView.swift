import SwiftUI

/**
 Displays today's usage summary and top apps with an editorial dashboard aesthetic.
 
 Features:
 - Large typographic header with date
 - Asymmetric summary cards with glass-morphism
 - Visual progress bars for app usage
 - Category distribution visualization
 - Staggered entrance animations
 */
struct TodayView: View {
    @State private var applications: [AppUsage] = []
    @State private var totalTime: TimeInterval = 0
    @State private var categoryBreakdown: [(category: Category, time: TimeInterval)] = []
    @State private var isLoaded = false
    
    private var topApps: [AppUsage] {
        applications.prefix(5).sorted {
            UsageDatabase.shared.getTodayTime(for: $0.id.uuidString) >
            UsageDatabase.shared.getTodayTime(for: $1.id.uuidString)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header with large date
                headerSection
                    .opacity(isLoaded ? 1 : 0)
                    .offset(y: isLoaded ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: isLoaded)
                
                // Summary cards - asymmetric layout
                summarySection
                    .opacity(isLoaded ? 1 : 0)
                    .offset(y: isLoaded ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isLoaded)
                
                if !applications.isEmpty {
                    // Category breakdown
                    categorySection
                        .opacity(isLoaded ? 1 : 0)
                        .offset(y: isLoaded ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: isLoaded)
                    
                    // Top apps with visual bars
                    topAppsSection
                        .opacity(isLoaded ? 1 : 0)
                        .offset(y: isLoaded ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: isLoaded)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.95),
                    Color(hex: "#F8F7FA").opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            loadData()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                isLoaded = true
            }
        }
        .onDisappear {
            isLoaded = false
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)
            
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text("Today")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                
                Text("·")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text(formattedTotalTime())
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        HStack(spacing: 16) {
            // Large card - Total Time
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(formattedTotalTime())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Text("Total Time")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // Progress indicator
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.08))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * dailyGoalProgress(), height: 6)
                            .animation(.easeOut(duration: 1).delay(0.5), value: isLoaded)
                    }
                }
                .frame(height: 6)
                
                Text("\(Int(dailyGoalProgress() * 100))% of daily goal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.textBackgroundColor))
                    .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 4)
            )
            
            // Small card - Apps Used
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "app.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(applications.count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text("Apps Used")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.textBackgroundColor))
                    .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("By Category")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("Time Distribution")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 20) {
                // Donut chart representation using ZStack
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.08), lineWidth: 24)
                        .frame(width: 120, height: 120)
                    
                    // Build segments
                    ForEach(0..<min(categoryBreakdown.count, 5), id: \.self) { index in
                        Circle()
                            .trim(
                                from: categoryStartAngle(for: index),
                                to: categoryEndAngle(for: index)
                            )
                            .stroke(
                                Color(hex: categoryBreakdown[index].category.color),
                                style: StrokeStyle(lineWidth: 24, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.8).delay(0.5 + Double(index) * 0.1), value: isLoaded)
                    }
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(categoryBreakdown.count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("categories")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(categoryBreakdown.prefix(4), id: \.category.id) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: item.category.color))
                                .frame(width: 8, height: 8)
                            
                            Text(item.category.name)
                                .font(.system(size: 13, weight: .medium))
                            
                            Spacer()
                            
                            Text(item.time.formatted())
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.textBackgroundColor))
                    .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Top Apps Section
    
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Apps")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("\(topApps.count) of \(applications.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.08))
                    )
            }
            
            VStack(spacing: 8) {
                ForEach(Array(topApps.enumerated()), id: \.element.id) { index, app in
                    let todayTime = UsageDatabase.shared.getTodayTime(for: app.id.uuidString)
                    let percentage = totalTime > 0 ? todayTime / totalTime : 0
                    
                    TodayAppRow(
                        app: app,
                        todayTime: todayTime,
                        percentage: percentage,
                        rank: index + 1
                    )
                    .opacity(isLoaded ? 1 : 0)
                    .offset(x: isLoaded ? 0 : -20)
                    .animation(.easeOut(duration: 0.5).delay(0.5 + Double(index) * 0.08), value: isLoaded)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadData() {
        applications = UsageDatabase.shared.getAllApplications()
            .sorted {
                UsageDatabase.shared.getTodayTime(for: $0.id.uuidString) >
                UsageDatabase.shared.getTodayTime(for: $1.id.uuidString)
            }
        totalTime = applications.reduce(0) {
            $0 + UsageDatabase.shared.getTodayTime(for: $1.id.uuidString)
        }
        
        // Calculate category breakdown
        let categories = UsageDatabase.shared.getAllCategories()
        categoryBreakdown = categories.compactMap { category in
            let categoryApps = applications.filter { $0.categoryId == category.id.uuidString }
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
    
    private func dailyGoalProgress() -> Double {
        let goal: TimeInterval = 8 * 3600 // 8 hours default goal
        return min(totalTime / goal, 1.0)
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
