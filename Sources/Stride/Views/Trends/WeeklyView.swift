import SwiftUI

/**
 * WeeklyView - A professional editorial dashboard for weekly usage patterns.
 * 
 * **Role in Stride:**
 * This view serves as the "Weekly Reflection" hub, providing a historical comparison
 * of the user's digital activity over the last 7 days. It focuses on identifying 
 * patterns, peak activity times, and consistency across the week.
 * 
 * **Key Features:**
 * 1. Summary Metrics: Displays average time, peak usage day, and weekly consistency.
 * 2. Activity Chart: An interactive bar chart showing daily utilization with selection feedback.
 * 3. Detailed Log: A vertical breakdown of each day's total time and relative percentage.
 * 
 * **Design Philosophy:**
 * - Minimalist "Warm Paper" aesthetic.
 * - Glassmorphism for chart and data containers.
 * - High-contrast editorial headers for a premium, reported feel.
 */
struct WeeklyView: View {
    @State private var weeklyData: [(date: Date, time: TimeInterval)] = []
    @State private var categoryTotals: [(category: Category, time: TimeInterval)] = []
    
    /// Controls the entrance animations for the dashboard components
    @State private var isLoaded = false
    
    /// The index of the day currently focused in the chart
    @State private var selectedDay: Int? = nil
    
    // MARK: - Design System Constants
    
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let brandMoss = Color(hex: "#4A7C59")
    private let brandTerracotta = Color(hex: "#C75B39")
    private let brandSlate = Color(hex: "#5B7C8C")
    
    /// The highest recorded time in the current week (used for scaling the chart)
    private var maxTime: TimeInterval {
        weeklyData.map { $0.time }.max() ?? 1
    }
    
    /// Sum of all tracked time for the 7-day period
    private var totalWeeklyTime: TimeInterval {
        weeklyData.reduce(0) { $0 + $1.time }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 48) {
                    // MARK: 1. Editorial Header
                    headerSection
                        .padding(.top, 24)
                    
                    if weeklyData.isEmpty {
                        emptyStateView
                    } else {
                        // MARK: 2. Weekly Performance Grid
                        metricsRow
                        
                        // MARK: 3. Categories This Week
                        categoriesSection
                        
                        // MARK: 4. Distribution Visualization
                        chartSection
                        
                        // MARK: 5. Historical Log
                        dayBreakdownSection
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Load fresh data from the database and trigger entrance effects
            loadWeeklyData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isLoaded = true
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(weekRangeString())
                .font(.system(size: 12, weight: .black))
                .foregroundColor(brandMoss)
                .tracking(2)
                .textCase(.uppercase)
            
            HStack(alignment: .lastTextBaseline, spacing: 16) {
                Text("Weekly Reflection")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(textColor)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(totalWeeklyTime))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                    Text("CUMULATIVE TIME")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(secondaryText)
                        .tracking(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
    }
    
    private var metricsRow: some View {
        HStack(spacing: 20) {
            SummaryMetricCard(
                title: "Daily Average",
                value: calculateAverage(),
                icon: "clock.arrow.circlepath",
                color: brandMoss,
                delay: 0.1,
                isLoaded: isLoaded
            )
            
            SummaryMetricCard(
                title: "Peak Activity",
                value: findMostActiveDayValue(),
                icon: "flame.fill",
                color: brandTerracotta,
                delay: 0.2,
                isLoaded: isLoaded
            )
            
            SummaryMetricCard(
                title: "Consistency",
                value: calculateConsistency(),
                icon: "checkmark.seal.fill",
                color: brandSlate,
                delay: 0.3,
                isLoaded: isLoaded
            )
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CATEGORIES THIS WEEK")
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            if categoryTotals.isEmpty {
                emptyCategoriesView
            } else {
                categoriesListView
            }
        }
        .padding(24)
        .background(glassMaterial)
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
        .animation(.spring(response: 0.6).delay(0.35), value: isLoaded)
    }
    
    private var emptyCategoriesView: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(secondaryText.opacity(0.5))
            Text("No category data for this week")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
        }
        .padding(.vertical, 20)
    }
    
    private var categoriesListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categoryTotals, id: \.category.id) { item in
                    categoryCard(for: item)
                }
            }
        }
    }
    
    private func categoryCard(for item: (category: Category, time: TimeInterval)) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: item.category.color))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.category.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textColor)
                Text(formatTime(item.time))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.6))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
    
    /**
     * An interactive bar chart showing usage trends.
     * 
     * Users can click individual bars to see exact time values for that day.
     */
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Daily Utilization")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(secondaryText)
                
                Spacer()
                
                if let selected = selectedDay {
                    let data = weeklyData[selected]
                    Text("\(dayLabel(for: data.date, full: true)) • \(formatTime(data.time))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(brandMoss)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            
            // The Bar Chart Container
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weeklyData.indices, id: \.self) { index in
                    let item = weeklyData[index]
                    let height = maxTime > 0 ? (item.time / maxTime) * 160 : 0
                    let isSelected = selectedDay == index
                    let isToday = Calendar.current.isDateInToday(item.date)
                    
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottom) {
                            // Empty Track
                            Capsule()
                                .fill(Color.black.opacity(0.02))
                                .frame(width: 32, height: 160)
                            
                            // Progress Bar
                            Capsule()
                                .fill(isToday ? brandTerracotta : brandMoss)
                                .frame(width: 32, height: max(CGFloat(height), 4))
                                .opacity(isSelected || selectedDay == nil ? 1 : 0.3)
                                .shadow(color: (isToday ? brandTerracotta : brandMoss).opacity(isSelected ? 0.3 : 0), radius: 8, x: 0, y: 4)
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDay = selectedDay == index ? nil : index
                            }
                        }
                        
                        Text(dayLabel(for: item.date))
                            .font(.system(size: 11, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? brandTerracotta : secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
            .padding(32)
            .background(glassMaterial)
        }
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 30)
        .animation(.spring(response: 0.6).delay(0.4), value: isLoaded)
    }
    
    private var dayBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("DETAILED LOG")
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundColor(secondaryText)
            
            VStack(spacing: 8) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, item in
                    let percentage = maxTime > 0 ? item.time / maxTime : 0
                    DayRow(
                        date: item.date,
                        time: item.time,
                        percentage: percentage,
                        isToday: Calendar.current.isDateInToday(item.date),
                        color: brandMoss
                    )
                    .opacity(isLoaded ? 1 : 0)
                    .offset(x: isLoaded ? 0 : -20)
                    .animation(.spring(response: 0.5).delay(0.5 + Double(index) * 0.05), value: isLoaded)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(brandMoss.opacity(0.2))
            Text("No usage data recorded for this week.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(secondaryText)
        }
        .padding(.vertical, 100)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    
    /**
     * Common glassmorphism style for weekly widgets.
     */
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
     * Aggregates usage time for the last 7 days from the UsageDatabase.
     */
    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Construct a list of the last 7 days (ordered chronologically)
        weeklyData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let time = UsageDatabase.shared.getTime(for: date)
            return (date, time)
        }.reversed()
        
        // Load category totals for the same 7-day period
        if let firstDay = weeklyData.first?.date {
            categoryTotals = UsageDatabase.shared.getCategoryTotalsForWeek(startingFrom: firstDay)
        }
    }
    
    private func weekRangeString() -> String {
        guard let first = weeklyData.first?.date,
              let last = weeklyData.last?.date else { return "THIS WEEK" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }
    
    private func dayLabel(for date: Date, full: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = full ? "EEEE, MMM d" : "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func calculateAverage() -> String {
        let activeDays = weeklyData.filter { $0.time > 0 }
        guard !activeDays.isEmpty else { return "0m" }
        let avg = activeDays.reduce(0) { $0 + $1.time } / Double(activeDays.count)
        return formatTime(avg)
    }
    
    private func findMostActiveDayValue() -> String {
        guard let max = weeklyData.max(by: { $0.time < $1.time }) else { return "0m" }
        return formatTime(max.time)
    }
    
    private func calculateConsistency() -> String {
        let activeDays = weeklyData.filter { $0.time > 0 }.count
        return "\(activeDays)/7 days"
    }
}

/**
 * DayRow - A refined comparison row for the weekly breakdown.
 */
struct DayRow: View {
    let date: Date
    let time: TimeInterval
    let percentage: Double
    let isToday: Bool
    let color: Color
    
    @State private var isHovered = false
    
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    var body: some View {
        HStack(spacing: 16) {
            // Day numeric badge
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isToday ? color.opacity(0.1) : Color.black.opacity(0.03))
                    .frame(width: 44, height: 44)
                
                VStack(spacing: 0) {
                    Text(dayNumber())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(dayShort())
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(secondaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(isToday ? "Today" : dayFullName())
                        .font(.system(size: 14, weight: isToday ? .bold : .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Spacer()
                    
                    Text(time.formatted())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isToday ? color : Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Relative progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.03))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(isToday ? Color(hex: "#C75B39") : color)
                            .frame(width: geo.size.width * CGFloat(percentage), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHovered ? Color.white : Color.white.opacity(0.5))
                .shadow(color: .black.opacity(isHovered ? 0.05 : 0.02), radius: isHovered ? 15 : 5, x: 0, y: isHovered ? 5 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isToday ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
    
    private func dayNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func dayShort() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayFullName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
