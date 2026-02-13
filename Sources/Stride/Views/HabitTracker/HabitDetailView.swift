import SwiftUI

/**
 * HabitDetailView - Detailed view of a habit with statistics and history
 *
 * Features:
 * - Full habit information display
 * - Streak indicators (current and longest)
 * - Calendar heatmap of completion history
 * - Statistics cards (completion rate, total, average)
 * - Recent entries list
 * - Edit and delete actions
 */
struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var statistics: HabitStatistics?
    @State private var streak: HabitStreak?
    @State private var todayEntry: HabitEntry?
    @State private var recentEntries: [HabitEntry] = []
    @State private var showingDeleteConfirmation = false
    @State private var isAnimating = false
    
    // Dark Forest theme
    private let backgroundColor = Color(hex: "#0F1F17")
    private let cardBackground = Color(hex: "#1A2820")
    private let accentColor = Color(hex: "#4A7C59")
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with icon and name
                    headerSection
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    // Streak indicator
                    if let streak = streak {
                        HabitStreakIndicator(
                            currentStreak: streak.currentStreak,
                            longestStreak: streak.longestStreak
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    }
                    
                    // Statistics cards
                    if let stats = statistics {
                        statisticsSection(stats: stats)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    
                    // Calendar heatmap
                    if let stats = statistics {
                        heatmapSection(stats: stats)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    
                    // Recent entries
                    if !recentEntries.isEmpty {
                        recentEntriesSection
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    
                    // Action buttons
                    actionsSection
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(24)
            }
        }
        .navigationTitle(habit.name)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(Color(hex: "#9A9A9A"))
            }
        }
        .onAppear {
            loadData()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                isAnimating = true
            }
        }
        .alert("Delete Habit?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("This will permanently delete \"\(habit.name)\" and all its history. This action cannot be undone.")
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: habit.color).opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(Color(hex: habit.color))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(habit.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label(habit.type.displayName, systemImage: habit.type.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                    
                    Text("•")
                        .foregroundColor(Color(hex: "#666666"))
                    
                    Text(habit.formattedTarget)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
                
                if habit.reminderEnabled, let time = habit.reminderTime {
                    Label(formattedTime(time), systemImage: "bell.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
        )
    }
    
    private func statisticsSection(stats: HabitStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Completion Rate",
                    value: stats.formattedCompletionRate,
                    icon: "chart.pie.fill",
                    color: Color(hex: habit.color)
                )
                
                StatCard(
                    title: "Total",
                    value: stats.formattedTotal,
                    icon: "sum",
                    color: Color(hex: habit.color)
                )
                
                StatCard(
                    title: "Average",
                    value: stats.formattedAverage,
                    icon: "chart.bar.fill",
                    color: Color(hex: habit.color)
                )
            }
        }
    }
    
    private func heatmapSection(stats: HabitStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 84 Days")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HabitCalendarHeatmap(
                data: stats.monthlyData,
                habitType: habit.type,
                targetValue: habit.targetValue
            )
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
            )
        }
    }
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Entries")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(recentEntries.prefix(7)) { entry in
                    HabitEntryRow(
                        entry: entry,
                        habitType: habit.type,
                        accentColor: Color(hex: habit.color)
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
            )
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: onEdit) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Habit")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor)
                )
            }
            .buttonStyle(.plain)
            
            Button(action: { showingDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Habit")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#9C3D2F"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#9C3D2F").opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        statistics = HabitDatabase.shared.getStatistics(for: habit)
        streak = HabitDatabase.shared.getStreak(for: habit)
        todayEntry = HabitDatabase.shared.getEntry(for: habit.id, on: Date())
        recentEntries = HabitDatabase.shared.getEntries(for: habit.id).sorted { $0.date > $1.date }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

/**
 * Statistics card component
 */
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#808080"))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#263328"))
        )
    }
}

/**
 * Entry row component
 */
struct HabitEntryRow: View {
    let entry: HabitEntry
    let habitType: HabitType
    let accentColor: Color
    
    var body: some View {
        HStack {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date.formattedShort)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                if entry.date.isToday {
                    Text("Today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(accentColor)
                } else if entry.date.isYesterday {
                    Text("Yesterday")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#808080"))
                }
            }
            
            Spacer()
            
            // Value
            HStack(spacing: 8) {
                if entry.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)
                }
                
                Text(entry.formattedValue(for: habitType))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(entry.isCompleted ? accentColor : Color(hex: "#9A9A9A"))
            }
        }
        .padding(.vertical, 8)
    }
}