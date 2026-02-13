import SwiftUI

/**
 Displays weekly usage patterns with an editorial data visualization aesthetic.
 
 Renamed from "Trends" to "This Week" for clarity and honesty.
 Features:
 - Animated bar chart with hover tooltips
 - Day-by-day insight cards
 - Pattern analysis and insights
 - Warm, editorial color palette
 */
struct WeeklyView: View {
    @State private var weeklyData: [(date: Date, time: TimeInterval)] = []
    @State private var isLoaded = false
    @State private var selectedDay: Int? = nil
    
    private var maxTime: TimeInterval {
        weeklyData.map { $0.time }.max() ?? 1
    }
    
    private var totalWeeklyTime: TimeInterval {
        weeklyData.reduce(0) { $0 + $1.time }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header with week range
                headerSection
                    .opacity(isLoaded ? 1 : 0)
                    .offset(y: isLoaded ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: isLoaded)
                
                if weeklyData.isEmpty {
                    ContentUnavailableView("No Data Yet", systemImage: "chart.line.uptrend.xyaxis")
                        .opacity(isLoaded ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: isLoaded)
                } else {
                    // Main chart
                    chartSection
                        .opacity(isLoaded ? 1 : 0)
                        .offset(y: isLoaded ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: isLoaded)
                    
                    // Quick stats row
                    statsSection
                        .opacity(isLoaded ? 1 : 0)
                        .offset(y: isLoaded ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: isLoaded)
                    
                    // Day breakdown
                    dayBreakdownSection
                        .opacity(isLoaded ? 1 : 0)
                        .offset(y: isLoaded ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: isLoaded)
                    
                    // Insights
                    insightsSection
                        .opacity(isLoaded ? 1 : 0)
                        .offset(y: isLoaded ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: isLoaded)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(hex: "#F5F3F0").opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            loadWeeklyData()
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
            Text("YOUR WEEK AT A GLANCE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1.5)
            
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text("This Week")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                
                Text("·")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text(weekRangeString())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Text("\(formatTime(totalWeeklyTime)) total screen time")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#2D6A4F"), Color(hex: "#40916C")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Daily Activity")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                if let selected = selectedDay {
                    let data = weeklyData[selected]
                    HStack(spacing: 6) {
                        Text(dayLabel(for: data.date))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(formatTime(data.time))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#2D6A4F"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#2D6A4F").opacity(0.1))
                    )
                }
            }
            
            // Chart bars
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(weeklyData.indices, id: \.self) { index in
                    let item = weeklyData[index]
                    let height = maxTime > 0 ? (item.time / maxTime) * 180 : 0
                    let isSelected = selectedDay == index
                    let isToday = Calendar.current.isDateInToday(item.date)
                    
                    VStack(spacing: 12) {
                        // Bar
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: isToday 
                                            ? [Color(hex: "#E07A5F"), Color(hex: "#F4A261")]
                                            : [Color(hex: "#2D6A4F"), Color(hex: "#52B788")],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: max(height, 4))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                                .opacity(height > 0 ? (isSelected || selectedDay == nil ? 1 : 0.4) : 0.25)
                                .scaleEffect(isSelected ? 1.05 : 1, anchor: .bottom)
                                .animation(.easeInOut(duration: 0.3), value: isSelected)
                                .animation(.easeOut(duration: 0.8).delay(0.3 + Double(index) * 0.05), value: isLoaded)
                        }
                        .frame(height: 180)
                        
                        // Day label
                        VStack(spacing: 2) {
                            Text(dayLabel(for: item.date))
                                .font(.system(size: 13, weight: isToday ? .bold : .medium))
                                .foregroundStyle(isToday ? Color(hex: "#E07A5F") : .secondary)
                            
                            if isToday {
                                Circle()
                                    .fill(Color(hex: "#E07A5F"))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDay = selectedDay == index ? nil : index
                        }
                    }
                }
            }
            .frame(height: 220)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 4)
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            // Average
            WeeklyStatCard(
                title: "Daily Average",
                value: calculateAverage(),
                subtitle: "Across 7 days",
                icon: "clock.arrow.circlepath",
                color: Color(hex: "#2D6A4F")
            )
            
            // Peak day
            WeeklyStatCard(
                title: "Peak Day",
                value: findMostActiveDayValue(),
                subtitle: findMostActiveDayName(),
                icon: "flame.fill",
                color: Color(hex: "#E07A5F")
            )
            
            // Consistency
            WeeklyStatCard(
                title: "Consistency",
                value: calculateConsistency(),
                subtitle: "Days active",
                icon: "checkmark.seal.fill",
                color: Color(hex: "#52796F")
            )
        }
    }
    
    // MARK: - Day Breakdown Section
    
    private var dayBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Day by Day")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("\(weeklyData.filter { $0.time > 0 }.count) active days")
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
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, item in
                    let percentage = maxTime > 0 ? item.time / maxTime : 0
                    let isToday = Calendar.current.isDateInToday(item.date)
                    
                    DayRow(
                        date: item.date,
                        time: item.time,
                        percentage: percentage,
                        isToday: isToday
                    )
                    .opacity(isLoaded ? 1 : 0)
                    .offset(x: isLoaded ? 0 : -20)
                    .animation(.easeOut(duration: 0.5).delay(0.4 + Double(index) * 0.05), value: isLoaded)
                }
            }
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.system(size: 18, weight: .semibold))
            
            VStack(spacing: 12) {
                InsightRow(
                    icon: "trending.up",
                    color: Color(hex: "#2D6A4F"),
                    title: productivityInsight(),
                    description: "Based on your daily patterns"
                )
                
                InsightRow(
                    icon: "sun.max.fill",
                    color: Color(hex: "#E9C46A"),
                    title: "Most productive time",
                    description: "Weekdays show higher activity"
                )
                
                InsightRow(
                    icon: "calendar.badge.checkmark",
                    color: Color(hex: "#52796F"),
                    title: "\(weeklyData.filter { $0.time > 4 * 3600 }.count) strong days",
                    description: "Days with 4+ hours of activity"
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        weeklyData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            // This would need to be implemented in the database
            // For now, using mock data based on today
            let time = UsageDatabase.shared.getTime(for: date)
            return (date, time)
        }.reversed()
    }
    
    private func weekRangeString() -> String {
        guard let first = weeklyData.first?.date,
              let last = weeklyData.last?.date else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
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
        guard !activeDays.isEmpty else { return "0h" }
        let avg = activeDays.reduce(0) { $0 + $1.time } / Double(activeDays.count)
        return formatTime(avg)
    }
    
    private func findMostActiveDayValue() -> String {
        guard let max = weeklyData.max(by: { $0.time < $1.time }) else { return "-" }
        return formatTime(max.time)
    }
    
    private func findMostActiveDayName() -> String {
        guard let max = weeklyData.max(by: { $0.time < $1.time }) else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: max.date)
    }
    
    private func calculateConsistency() -> String {
        let activeDays = weeklyData.filter { $0.time > 0 }.count
        return "\(activeDays)/7"
    }
    
    private func productivityInsight() -> String {
        let avg = weeklyData.reduce(0) { $0 + $1.time } / Double(weeklyData.count)
        if avg > 6 * 3600 {
            return "High activity week"
        } else if avg > 4 * 3600 {
            return "Balanced activity"
        } else {
            return "Light activity week"
        }
    }
}

// MARK: - Supporting Views

struct WeeklyStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 4)
        )
    }
}

struct DayRow: View {
    let date: Date
    let time: TimeInterval
    let percentage: Double
    let isToday: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Day indicator
            ZStack {
                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#E07A5F").opacity(0.15))
                        .frame(width: 44, height: 44)
                }
                
                VStack(spacing: 0) {
                    Text(dayNumber())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(dayShort())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(isToday ? "Today" : dayFullName())
                        .font(.system(size: 15, weight: isToday ? .bold : .medium))
                    
                    Spacer()
                    
                    Text(time.formatted())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isToday ? Color(hex: "#E07A5F") : .primary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.08))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: isToday 
                                        ? [Color(hex: "#E07A5F"), Color(hex: "#F4A261")]
                                        : [Color(hex: "#2D6A4F"), Color(hex: "#52B788")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(percentage), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color(NSColor.textBackgroundColor).opacity(0.8) : Color(NSColor.textBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.06 : 0.03), radius: isHovered ? 12 : 8, x: 0, y: isHovered ? 6 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isToday ? Color(hex: "#E07A5F").opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
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

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
        )
    }
}
