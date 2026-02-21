import SwiftUI

/**
 * WeeklyLogView - Main container for the weekly focus session tracker.
 */
struct WeeklyLogView: View {
    @State private var currentWeekStart: Date
    @State private var entries: [WeeklyLogEntry] = []
    @State private var viewMode: ViewMode = .list
    @State private var showingAddEntry = false
    @State private var editingEntry: WeeklyLogEntry?
    @State private var entryToDelete: WeeklyLogEntry?
    @State private var isAnimating = false
    
    enum ViewMode { case calendar, list }
    
    private let backgroundColor = Color(hex: "#FAF8F4")
    private let cardBackground = Color.white
    private let accentColor = Color(hex: "#C75B39")
    private let textColor = Color(hex: "#2C2C2C")
    private let secondaryText = Color(hex: "#616161")
    private let winColor = Color(hex: "#D4A853")
    
    init() {
        _currentWeekStart = State(initialValue: Date().startOfWeek)
    }
    
    var weekInfo: WeekInfo { currentWeekStart.weekInfo }
    var weeklyTotal: Double { entries.reduce(0) { $0 + $1.timeSpent } }
    var weeklyMinutes: Int { entries.reduce(0) { $0 + $1.timeInMinutes } }
    var winsCount: Int { entries.filter { $0.isWinOfDay }.count }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView.padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)
                summaryBar.padding(.horizontal, 24).padding(.bottom, 20)
                viewToggle.padding(.horizontal, 24).padding(.bottom, 16)
                mainContent.padding(.horizontal, 24).padding(.bottom, 24)
            }
            
            // MARK: Premium Confirmation Overlay
            if let entry = entryToDelete {
                deletionConfirmationOverlay(for: entry)
            }
        }
        .onAppear {
            loadEntries()
            withAnimation(DesignSystem.Animation.entrance.spring) { isAnimating = true }
        }
        .sheet(isPresented: $showingAddEntry) {
            WeeklyLogEntryForm(entry: nil, weekStart: currentWeekStart) { _ in loadEntries() }
        }
        .sheet(item: $editingEntry) { entry in
            WeeklyLogEntryForm(entry: entry, weekStart: currentWeekStart) { _ in loadEntries() }
        }
    }
    
    // MARK: - Subviews
    
    /**
     * A high-polish confirmation overlay.
     */
    private func deletionConfirmationOverlay(for entry: WeeklyLogEntry) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.spring) { entryToDelete = nil } }
            
            VStack(spacing: 0) {
                // Warning Banner
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    Text("PERMANENT ACTION")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(accentColor)
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Remove this entry?")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(textColor)
                        
                        Text("You're about to delete the session for '\(entry.task)'. This contribution to your week will be lost forever.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: { withAnimation(.spring) { entryToDelete = nil } }) {
                            Text("Keep Entry")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.05)))
                                .foregroundColor(textColor)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { 
                            deleteEntry(entry)
                            withAnimation(.spring) { entryToDelete = nil }
                        }) {
                            Text("Confirm Delete")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(accentColor))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 40)
            }
            .frame(width: 440)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 40, x: 0, y: 20)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
        .zIndex(100)
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly Log").font(.system(size: 28, weight: .bold)).foregroundColor(textColor)
                Text("Track your focus sessions and wins").font(.system(size: 13)).foregroundColor(secondaryText)
            }
            Spacer()
            HStack(spacing: 12) {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(textColor).frame(width: 36, height: 36).background(Circle().fill(cardBackground).shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)).contentShape(Circle())
                }.buttonStyle(.plain)
                VStack(spacing: 2) {
                    Text(weekInfo.formattedRange).font(.system(size: 15, weight: .semibold)).foregroundColor(textColor)
                    Text("Week \(weekInfo.weekNumber)").font(.system(size: 11, weight: .medium)).foregroundColor(secondaryText)
                }.frame(minWidth: 140)
                Button(action: nextWeek) {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundColor(textColor).frame(width: 36, height: 36).background(Circle().fill(cardBackground).shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)).contentShape(Circle())
                }.buttonStyle(.plain)
            }
            Spacer()
            Button(action: { showingAddEntry = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                    Text("Add Entry").font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(accentColor).shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 3)).foregroundColor(.white)
            }.buttonStyle(.plain)
        }
    }
    
    private var summaryBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "clock").font(.system(size: 20, weight: .medium)).foregroundColor(accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Total").font(.system(size: 11, weight: .medium)).foregroundColor(secondaryText)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", weeklyTotal)).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(textColor)
                        Text("pomodoros").font(.system(size: 13, weight: .medium)).foregroundColor(secondaryText)
                    }
                    Text("(\(weeklyMinutes) min)").font(.system(size: 12, weight: .medium)).foregroundColor(secondaryText.opacity(0.8))
                }
            }
            Spacer()
            Divider().frame(height: 50).background(Color.black.opacity(0.1))
            Spacer()
            HStack(spacing: 16) {
                ForEach(weekInfo.days, id: \.self) { day in
                    let total = (entries.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.timeSpent })
                    VStack(spacing: 6) {
                        Text(day.shortDayName).font(.system(size: 11, weight: .semibold)).foregroundColor(secondaryText)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(total > 0 ? accentColor.opacity(0.15) : Color.black.opacity(0.04)).frame(width: 44, height: 44)
                            Text(total > 0 ? String(format: "%.1f", total) : "-").font(.system(size: 13, weight: .bold)).foregroundColor(total > 0 ? accentColor : secondaryText.opacity(0.4))
                        }
                        Text(day.dayOfMonth).font(.system(size: 10, weight: .medium)).foregroundColor(secondaryText.opacity(0.7))
                    }
                }
            }
            Spacer()
            Divider().frame(height: 50).background(Color.black.opacity(0.1))
            Spacer()
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(winColor.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "star.fill").font(.system(size: 20, weight: .medium)).foregroundColor(winColor.opacity(0.9))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wins").font(.system(size: 11, weight: .medium)).foregroundColor(secondaryText)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(winsCount)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(textColor)
                        Text(winsCount == 1 ? "win" : "wins").font(.system(size: 13, weight: .medium)).foregroundColor(secondaryText)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground).shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3))
    }
    
    private var viewToggle: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewMode = .calendar } }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar").font(.system(size: 14, weight: .medium))
                    Text("Calendar").font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(viewMode == .calendar ? accentColor : Color.clear)).contentShape(Rectangle()).foregroundColor(viewMode == .calendar ? .white : textColor)
            }.buttonStyle(.plain)
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewMode = .list } }) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet").font(.system(size: 14, weight: .medium))
                    Text("List").font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(viewMode == .list ? accentColor : Color.clear)).contentShape(Rectangle()).foregroundColor(viewMode == .list ? .white : textColor)
            }.buttonStyle(.plain)
        }
        .padding(4).background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.black.opacity(0.04)))
    }
    
    private var mainContent: some View {
        Group {
            if entries.isEmpty {
                emptyStateView
            } else {
                switch viewMode {
                case .calendar:
                    WeeklyLogCalendarView(entries: entries, weekStart: currentWeekStart, onEdit: { entry in editingEntry = entry }, onDelete: { entry in withAnimation(.spring) { entryToDelete = entry } })
                case .list:
                    WeeklyLogListView(entries: entries, onEdit: { entry in editingEntry = entry }, onDelete: { entry in withAnimation(.spring) { entryToDelete = entry } })
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(RadialGradient(colors: [accentColor.opacity(0.1), Color.clear], center: .center, startRadius: 0, endRadius: 80)).frame(width: 160, height: 160)
                Image(systemName: "clock.badge.checkmark").font(.system(size: 48, weight: .light)).foregroundColor(accentColor.opacity(0.7))
            }
            VStack(spacing: 8) {
                Text("No Entries This Week").font(.system(size: 20, weight: .semibold)).foregroundColor(textColor)
                Text("Start tracking your pomodoro sessions").font(.system(size: 14)).foregroundColor(secondaryText)
            }
            Button(action: { showingAddEntry = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                    Text("Add First Entry").font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 24).padding(.vertical, 12).background(Capsule().strokeBorder(accentColor, lineWidth: 1.5)).foregroundColor(accentColor)
            }.buttonStyle(.plain).padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground).shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 3))
    }
    
    private func loadEntries() { 
        entries = WeeklyLogDatabase.shared.getEntriesForWeek(startingFrom: currentWeekStart)
    }
    private func previousWeek() { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? currentWeekStart; loadEntries() } }
    private func nextWeek() { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart; loadEntries() } }
    private func deleteEntry(_ entry: WeeklyLogEntry) { WeeklyLogDatabase.shared.deleteEntry(id: entry.id); loadEntries() }
}
