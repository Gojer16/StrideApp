import SwiftUI

/**
 * WeeklyLogView - Main container for the weekly focus session tracker
 *
 * Features:
 * - Week navigation (previous/next arrows)
 * - View toggle between Calendar and List
 * - Weekly summary bar with totals
 * - Quick add button for new entries
 * - Opens to last week by default
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Warm cream background
 * - Terracotta accents
 * - Clean white cards with soft shadows
 */
struct WeeklyLogView: View {
    @State private var currentWeekStart: Date
    @State private var entries: [WeeklyLogEntry] = []
    @State private var viewMode: ViewMode = .list
    @State private var showingAddEntry = false
    @State private var editingEntry: WeeklyLogEntry?
    @State private var isAnimating = false
    
    enum ViewMode {
        case calendar
        case list
    }
    
    private let backgroundColor = Color(hex: "#FAF8F4")
    private let cardBackground = Color.white
    private let accentColor = Color(hex: "#C75B39")
    private let textColor = Color(hex: "#2C2C2C")
    private let secondaryText = Color(hex: "#616161")
    private let winColor = Color(hex: "#D4A853")  // Gold
    
    init() {
        // Initialize with last week (one week ago from today)
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        _currentWeekStart = State(initialValue: lastWeek.startOfWeek)
    }
    
    var weekInfo: WeekInfo {
        return currentWeekStart.weekInfo
    }
    
    var weeklyTotal: Double {
        entries.reduce(0) { $0 + $1.timeSpent }
    }
    
    var weeklyMinutes: Int {
        entries.reduce(0) { $0 + $1.timeInMinutes }
    }
    
    var winsCount: Int {
        entries.filter { $0.isWinOfDay }.count
    }
    
    var dailyTotals: [Date: Double] {
        var totals: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            totals[dayStart, default: 0] += entry.timeSpent
        }
        
        return totals
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                
                // Summary bar
                summaryBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                // View toggle
                viewToggle
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                // Main content
                mainContent
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            loadEntries()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            WeeklyLogEntryForm(entry: nil, weekStart: currentWeekStart) { _ in
                loadEntries()
            }
        }
        .sheet(item: $editingEntry) { entry in
            WeeklyLogEntryForm(entry: entry, weekStart: currentWeekStart) { _ in
                loadEntries()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly Log")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(textColor)
                
                Text("Track your focus sessions and wins")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(secondaryText)
            }
            
            Spacer()
            
            // Week navigator
            HStack(spacing: 12) {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(textColor)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(cardBackground)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
                
                VStack(spacing: 2) {
                    Text(weekInfo.formattedRange)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Week \(weekInfo.weekNumber)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryText)
                }
                .frame(minWidth: 140)
                
                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(textColor)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(cardBackground)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Add button
            Button(action: { showingAddEntry = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add Entry")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentColor)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 3)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Summary Bar
    private var summaryBar: some View {
        HStack(spacing: 0) {
            // Weekly total
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "clock")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", weeklyTotal))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                        
                        Text("pomodoros")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryText)
                    }
                    
                    Text("(\(weeklyMinutes) min)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText.opacity(0.8))
                }
            }
            
            Spacer()
            
            Divider()
                .frame(height: 50)
                .background(Color.black.opacity(0.1))
            
            Spacer()
            
            // Daily breakdown
            HStack(spacing: 16) {
                ForEach(weekInfo.days, id: \.self) { day in
                    let total = dailyTotals[Calendar.current.startOfDay(for: day)] ?? 0
                    let hasEntries = total > 0
                    
                    VStack(spacing: 6) {
                        Text(day.shortDayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(secondaryText)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(hasEntries ? accentColor.opacity(0.15) : Color.black.opacity(0.04))
                                .frame(width: 44, height: 44)
                            
                            if hasEntries {
                                Text(String(format: "%.1f", total))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(accentColor)
                            } else {
                                Text("-")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryText.opacity(0.4))
                            }
                        }
                        
                        Text(day.dayOfMonth)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(secondaryText.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Divider()
                .frame(height: 50)
                .background(Color.black.opacity(0.1))
            
            Spacer()
            
            // Wins count
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(winColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(winColor.opacity(0.9))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wins")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(winsCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                        
                        Text(winsCount == 1 ? "win" : "wins")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryText)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3)
        )
    }
    
    // MARK: - View Toggle
    private var viewToggle: some View {
        HStack(spacing: 0) {
            Button(action: { viewMode = .calendar }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                    Text("Calendar")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(viewMode == .calendar ? accentColor : Color.clear)
                )
                .foregroundColor(viewMode == .calendar ? .white : textColor)
            }
            .buttonStyle(.plain)
            
            Button(action: { viewMode = .list }) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .medium))
                    Text("List")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(viewMode == .list ? accentColor : Color.clear)
                )
                .foregroundColor(viewMode == .list ? .white : textColor)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.04))
        )
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            if entries.isEmpty {
                emptyStateView
            } else {
                switch viewMode {
                case .calendar:
                    WeeklyLogCalendarView(
                        entries: entries,
                        weekStart: currentWeekStart,
                        onEdit: { entry in
                            editingEntry = entry
                        },
                        onDelete: { entry in
                            deleteEntry(entry)
                        }
                    )
                case .list:
                    WeeklyLogListView(
                        entries: entries,
                        onEdit: { entry in
                            editingEntry = entry
                        },
                        onDelete: { entry in
                            deleteEntry(entry)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(accentColor.opacity(0.7))
            }
            
            VStack(spacing: 8) {
                Text("No Entries This Week")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("Start tracking your pomodoro sessions")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
            }
            
            Button(action: { showingAddEntry = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add First Entry")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .strokeBorder(accentColor, lineWidth: 1.5)
                )
                .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3)
        )
    }
    
    // MARK: - Actions
    private func loadEntries() {
        entries = WeeklyLogDatabase.shared.getEntriesForWeek(startingFrom: currentWeekStart)
    }
    
    private func previousWeek() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? currentWeekStart
            loadEntries()
        }
    }
    
    private func nextWeek() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
            loadEntries()
        }
    }
    
    private func deleteEntry(_ entry: WeeklyLogEntry) {
        WeeklyLogDatabase.shared.deleteEntry(id: entry.id)
        loadEntries()
    }
}
