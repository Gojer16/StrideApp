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
    @EnvironmentObject private var appState: AppState
    @StateObject private var database = UsageDatabase.shared
    @State private var weeklyData: [(date: Date, time: TimeInterval)] = []
    @State private var persistedWeeklyData: [(date: Date, time: TimeInterval)] = []
    @State private var categoryTotals: [(category: Category, time: TimeInterval)] = []
    
    /// Controls the entrance animations for the dashboard components
    @State private var isLoaded = false
    
    /// The index of the day currently focused in the chart
    @State private var selectedDay: Int? = nil
    
    @State private var showOverview = true
    @State private var showCategories = false
    @State private var showLog = false
    
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
    
    private var hasUsageData: Bool {
        weeklyData.contains { $0.time > 0 }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: 1. Editorial Header
                    headerSection
                        .padding(.top, 12)
                    
                    if !hasUsageData {
                        emptyStateView
                    } else {
                        sectionToggleBar
                        
                        if showOverview {
                            metricsStrip
                            compactChartCard
                        }
                        
                        if showCategories {
                            categoriesInlineSection
                        }
                        
                        if showLog {
                            compactLogCard
                        }
                        
                        if !showOverview && !showCategories && !showLog {
                            collapsedHint
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            refreshWeeklyData()
            withAnimation(DesignSystem.Animation.entrance.spring) {
                isLoaded = true
            }
        }
        .onChange(of: database.lastUpdate) {
            refreshWeeklyData()
        }
        .onChange(of: appState.elapsedTime) {
            applyLiveSessionOverlay()
        }
        .onChange(of: appState.activeAppName) {
            applyLiveSessionOverlay()
        }
    }
    
    // MARK: - Sections
    
    private var sectionToggleBar: some View {
        HStack(spacing: 0) {
            SectionToggleButton(
                title: "Overview",
                isOn: showOverview,
                color: brandMoss
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showOverview.toggle()
                }
            }
            
            SectionToggleButton(
                title: "Categories",
                isOn: showCategories,
                color: brandSlate
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCategories.toggle()
                }
            }
            
            SectionToggleButton(
                title: "Log",
                isOn: showLog,
                color: brandTerracotta
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showLog.toggle()
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
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
    
    private var metricsStrip: some View {
        HStack(spacing: 0) {
            CompactMetricSegment(
                title: "Daily Average",
                value: calculateAverage(),
                icon: "clock.arrow.circlepath",
                color: brandMoss
            )
            
            Divider().overlay(Color.black.opacity(0.08))
            
            CompactMetricSegment(
                title: "Peak Activity",
                value: findMostActiveDayValue(),
                icon: "flame.fill",
                color: brandTerracotta
            )
            
            Divider().overlay(Color.black.opacity(0.08))
            
            CompactMetricSegment(
                title: "Consistency",
                value: calculateConsistency(),
                icon: "checkmark.seal.fill",
                color: brandSlate
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .shadow(color: .black.opacity(0.025), radius: 10, x: 0, y: 3)
        )
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 14)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.2), value: isLoaded)
    }
    
    private var categoriesInlineSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("CATEGORIES")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.4)
                    .foregroundColor(secondaryText)
                
                if !categoryTotals.isEmpty {
                    Text("TOP CATEGORIES")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.2)
                        .foregroundColor(brandMoss.opacity(0.9))
                }
            }
            
            if categoryTotals.isEmpty {
                Text("No category data for this week")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)
            } else {
                categoriesListView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 10)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.28), value: isLoaded)
    }
    
    private var collapsedHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.slash")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(secondaryText.opacity(0.8))
            Text("All sections hidden. Toggle one to view this week's data.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.5))
        )
    }
    
    private var categoriesListView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(categoryTotals.enumerated()), id: \.element.category.id) { index, item in
                    categoryCard(for: item, rank: index + 1)
                }
            }
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 132), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(Array(categoryTotals.enumerated()), id: \.element.category.id) { index, item in
                    categoryCard(for: item, rank: index + 1)
                }
            }
        }
    }
    
    private func categoryCard(for item: (category: Category, time: TimeInterval), rank: Int) -> some View {
        let isTopThree = rank <= 3
        let isTopOne = rank == 1
        let accent = Color(hex: item.category.color)
        let rankingLabel = rank == 1 ? "1st" : (rank == 2 ? "2nd" : "3rd")
        
        return HStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 9, height: 9)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.category.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textColor)
                    Text(formatTime(item.time))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(secondaryText)
                }
            }
            
            Spacer(minLength: 2)
            
            HStack(spacing: 6) {
                if isTopOne {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accent.opacity(0.72))
                }
                
                if isTopThree {
                    Text(rankingLabel)
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.6)
                        .foregroundColor(accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(accent.opacity(0.14))
                        )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(minHeight: 46, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(isTopThree ? Color.white.opacity(0.96) : Color.white.opacity(0.84))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isTopThree ? accent.opacity(0.28) : Color.black.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(
            color: isTopThree ? accent.opacity(0.12) : .black.opacity(0.02),
            radius: isTopThree ? 8 : 4,
            x: 0,
            y: isTopThree ? 3 : 1
        )
    }
    
    private var compactChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Daily Utilization")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.3)
                    .foregroundColor(secondaryText)
                
                Spacer()
                
                if let selected = selectedDay {
                    let data = weeklyData[selected]
                    Text("\(dayLabel(for: data.date, full: true)) • \(formatTime(data.time))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(brandMoss)
                }
            }
            
            HStack(alignment: .bottom, spacing: 10) {
                yAxisTicks
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyData.indices, id: \.self) { index in
                        let item = weeklyData[index]
                        let height = maxTime > 0 ? (item.time / maxTime) * 116 : 0
                        let isSelected = selectedDay == index
                        let isToday = Calendar.current.isDateInToday(item.date)
                        
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottom) {
                                Capsule()
                                    .fill(Color.black.opacity(0.025))
                                    .frame(width: 26, height: 116)
                                
                                Capsule()
                                    .fill(isToday ? brandTerracotta : brandMoss)
                                    .frame(width: 26, height: max(CGFloat(height), 4))
                                    .opacity(isSelected || selectedDay == nil ? 1 : 0.3)
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
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
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 188)
        .background(glassMaterialCompact)
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 16)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.35), value: isLoaded)
    }
    
    private var yAxisTicks: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(chartTickValues.indices, id: \.self) { index in
                let tick = chartTickValues[index]
                Text(formatTime(tick))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(secondaryText.opacity(0.8))
                
                if index < chartTickValues.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(width: 34, height: 110, alignment: .trailing)
    }
    
    private var chartTickValues: [TimeInterval] {
        guard maxTime > 0 else { return [0, 0, 0] }
        return [maxTime, maxTime * 0.5, 0]
    }
    
    private var compactLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Log")
                .font(.system(size: 10, weight: .black))
                .tracking(1.3)
                .foregroundColor(secondaryText)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, item in
                        let percentage = maxTime > 0 ? item.time / maxTime : 0
                        CompactDayRow(
                            date: item.date,
                            formattedTime: formatTime(item.time),
                            percentage: percentage,
                            isToday: Calendar.current.isDateInToday(item.date),
                            color: brandMoss
                        )
                    }
                }
            }
            .frame(minHeight: 156, maxHeight: 156)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 188)
        .background(glassMaterialCompact)
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 16)
        .animation(DesignSystem.Animation.entrance.spring.delay(0.4), value: isLoaded)
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
    
    private var glassMaterialCompact: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.025), radius: 10, x: 0, y: 3)
    }
    
    /**
     * Aggregates usage time for the current calendar week (Monday through today).
     */
    private func refreshWeeklyData() {
        let weekDates = Self.weekDatesThroughToday()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let timesByDate = database.getTimes(for: weekDates)
            let persisted = weekDates.map { date in
                (date: date, time: timesByDate[date] ?? 0)
            }
            let categories: [(category: Category, time: TimeInterval)]
            if let firstDay = persisted.first?.date {
                categories = database.getCategoryTotalsForWeek(startingFrom: firstDay)
            } else {
                categories = []
            }
            
            DispatchQueue.main.async {
                persistedWeeklyData = persisted
                categoryTotals = categories
                applyLiveSessionOverlay()
            }
        }
    }
    
    private func applyLiveSessionOverlay() {
        weeklyData = Self.mergePersistedWeekData(
            persistedWeeklyData,
            with: appState.liveSessionSnapshot
        )
        
        if let selected = selectedDay, selected >= weeklyData.count {
            selectedDay = nil
        }
    }
    
    static func weekDatesThroughToday(referenceDate: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: referenceDate)
        
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        let startOfWeek = calendar.date(from: components) ?? today
        let dayCount = max(calendar.dateComponents([.day], from: startOfWeek, to: today).day ?? 0, 0) + 1
        
        return (0..<dayCount).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    static func mergePersistedWeekData(
        _ persisted: [(date: Date, time: TimeInterval)],
        with snapshot: AppState.LiveSessionSnapshot?,
        calendar: Calendar = .current
    ) -> [(date: Date, time: TimeInterval)] {
        guard let snapshot, snapshot.activeDuration > 0 else {
            return persisted
        }
        
        var merged = persisted
        let sessionDay = calendar.startOfDay(for: snapshot.startTime)
        
        if let index = merged.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: sessionDay) }) {
            merged[index].time += snapshot.activeDuration
        }
        
        return merged
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
        return "\(activeDays)/\(max(weeklyData.count, 1)) days"
    }
}

private struct CompactMetricSegment: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(1)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }
}

private struct SectionToggleButton: View {
    let title: String
    let isOn: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isOn ? color : Color(red: 0.42, green: 0.42, blue: 0.42))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isOn ? color.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactDayRow: View {
    let date: Date
    let formattedTime: String
    let percentage: Double
    let isToday: Bool
    let color: Color
    
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    var body: some View {
        HStack(spacing: 10) {
            Text(isToday ? "Today" : dayName())
                .font(.system(size: 14, weight: isToday ? .bold : .semibold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .frame(width: 74, alignment: .leading)
            
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
            
            Text(formattedTime)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isToday ? color : secondaryText)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isToday ? color.opacity(0.08) : Color.white.opacity(0.45))
        )
    }
    
    private func dayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

/**
 * DayRow - A refined comparison row for the weekly breakdown.
 */
struct DayRow: View {
    let date: Date
    let time: TimeInterval
    let formattedTime: String
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
                    
                    Text(formattedTime)
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
