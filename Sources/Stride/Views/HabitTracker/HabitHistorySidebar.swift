import SwiftUI
import Charts

/**
 * HabitHistorySidebar - Slide-in panel showing habit entry history.
 * 
 * Features:
 * - 30-day sparkline chart
 * - Scrollable list of last 14 entries
 * - Read-only view
 * - Warm Paper aesthetic
 */
struct HabitHistorySidebar: View {
    let habit: Habit
    let entries: [HabitEntry]
    let onClose: () -> Void
    
    @State private var isVisible = false
    
    // Design System - Warm Paper
    private let backgroundColor = Color(red: 0.98, green: 0.973, blue: 0.957)
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor: Color
    
    init(habit: Habit, entries: [HabitEntry], onClose: @escaping () -> Void) {
        self.habit = habit
        self.entries = entries
        self.onClose = onClose
        self.accentColor = Color(hex: habit.color)
    }
    
    private var last30DaysData: [(Date, Double)] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        var dataPoints: [(Date, Double)] = []
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: thirtyDaysAgo) {
                let dayStart = calendar.startOfDay(for: date)
                let value = entries.first(where: { calendar.isDate($0.date, inSameDayAs: date) })?.value ?? 0
                dataPoints.append((dayStart, value))
            }
        }
        return dataPoints
    }
    
    private var last14Entries: [HabitEntry] {
        Array(entries.sorted(by: { $0.date > $1.date }).prefix(14))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Dimmed background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { closeWithAnimation() }
            
            // Sidebar panel
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // 30-day chart
                        chartSection
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        Divider()
                        
                        // Recent entries list
                        entriesListSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                    }
                }
            }
            .frame(width: 400)
            .background(backgroundColor)
            .offset(x: isVisible ? 0 : 400)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Habit icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("HISTORY")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(secondaryText)
                    .tracking(1)
            }
            
            Spacer()
            
            // Close button
            Button(action: closeWithAnimation) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 Days")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(textColor)
            
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(last30DaysData, id: \.0) { date, value in
                        LineMark(
                            x: .value("Date", date),
                            y: .value("Sessions", value)
                        )
                        .foregroundStyle(accentColor)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", date),
                            y: .value("Sessions", value)
                        )
                        .foregroundStyle(accentColor.opacity(0.2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 120)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(secondaryText)
                    }
                }
            } else {
                // Fallback for older macOS versions
                Text("Chart requires macOS 13+")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.02))
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
    }
    
    private var entriesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(textColor)
            
            if last14Entries.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 8) {
                    ForEach(last14Entries) { entry in
                        entryRow(entry)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundColor(secondaryText.opacity(0.3))
            
            Text("No entries yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
            
            Text("Start tracking to see your history")
                .font(.system(size: 12))
                .foregroundColor(secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func entryRow(_ entry: HabitEntry) -> some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textColor)
                
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Value badge
            Text(entry.formattedValue(for: habit.type))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(12)
        .background(cardBackground)
        .cornerRadius(12)
    }
    
    private func closeWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onClose()
        }
    }
}
