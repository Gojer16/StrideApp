import SwiftUI

/**
 * QuickActionsBar - Floating action bar for the homepage.
 *
 * Provides quick access to common actions:
 * - Log Focus Session (opens Weekly Log form)
 * - Quick Habit Check (opens habit overlay)
 * - View Full Report (jumps to Today view)
 */
struct QuickActionsBar: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingLogEntry = false
    @State private var showingHabitOverlay = false
    
    // MARK: - Design Constants
    private let mossColor = Color(hex: "#4A7C59")
    private let terracottaColor = Color(hex: "#C75B39")
    private let slateColor = Color(hex: "#5B7C8C")
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    
    var body: some View {
        HStack(spacing: 12) {
            // Log Session Button
            QuickActionButton(
                icon: "plus.circle.fill",
                title: "Log Session",
                subtitle: "Record focus time",
                color: terracottaColor
            ) {
                showingLogEntry = true
            }
            
            Divider()
                .frame(height: 36)
                .opacity(0.3)
            
            // Quick Habit Button
            QuickActionButton(
                icon: "checkmark.circle.fill",
                title: "Habits",
                subtitle: "Quick check",
                color: mossColor
            ) {
                showingHabitOverlay = true
            }
            
            Divider()
                .frame(height: 36)
                .opacity(0.3)
            
            // View Report Button
            QuickActionButton(
                icon: "chart.bar.fill",
                title: "Report",
                subtitle: "Full details",
                color: slateColor
            ) {
                // Navigate to Today view via notification or direct action
                NotificationCenter.default.post(name: .navigateToToday, object: nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .sheet(isPresented: $showingLogEntry) {
            WeeklyLogEntryForm(entry: nil, weekStart: Date().startOfWeek) { _ in
                // Callback after save
            }
        }
        .overlay {
            if showingHabitOverlay {
                QuickHabitOverlay(isPresented: $showingHabitOverlay)
            }
        }
    }
}

/**
 * QuickActionButton - Individual action button for the action bar.
 */
private struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? color.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

/**
 * QuickHabitOverlay - Overlay for quick habit toggling.
 */
private struct QuickHabitOverlay: View {
    @Binding var isPresented: Bool
    @StateObject private var database = HabitDatabase.shared
    @State private var habits: [Habit] = []
    
    private let mossColor = Color(hex: "#4A7C59")
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14))
                            .foregroundColor(mossColor)
                        
                        Text("Quick Habit Check")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color.white)
                
                Divider()
                
                // Habit List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(activeHabits, id: \.id) { habit in
                            QuickHabitRow(habit: habit)
                        }
                    }
                    .padding(16)
                }
                .frame(maxHeight: 300)
            }
            .frame(width: 360)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 40, x: 0, y: 20)
        }
        .transition(.opacity)
        .onAppear {
            habits = database.getAllHabits()
        }
        .onChange(of: database.lastUpdate) {
            habits = database.getAllHabits()
        }
    }
    
    private var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }
}

/**
 * QuickHabitRow - Single habit row in the overlay.
 */
private struct QuickHabitRow: View {
    let habit: Habit
    @StateObject private var database = HabitDatabase.shared
    @State private var isCompleted: Bool = false
    
    private let mossColor = Color(hex: "#4A7C59")
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: toggle) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? mossColor : Color.black.opacity(0.06))
                        .frame(width: 28, height: 28)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text(habit.frequency.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            
            Spacer()
            
            // Streak
            let streak = database.getStreak(for: habit)
            if streak.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(hex: "#D4A853"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: "#D4A853").opacity(0.12))
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCompleted ? mossColor.opacity(0.06) : Color.black.opacity(0.02))
        )
        .onAppear {
            checkCompletion()
        }
        .onChange(of: database.lastUpdate) {
            checkCompletion()
        }
    }
    
    private func toggle() {
        let today = Date()
        
        if habit.type == .checkbox {
            if let existing = database.getEntry(for: habit.id, on: today) {
                database.addEntry(HabitEntry(
                    id: existing.id,
                    habitId: habit.id,
                    date: today,
                    value: existing.isCompleted ? 0.0 : 1.0,
                    notes: existing.notes
                ))
            } else {
                database.addEntry(HabitEntry(habitId: habit.id, date: today, value: 1.0))
            }
        }
    }
    
    private func checkCompletion() {
        if let entry = database.getEntry(for: habit.id, on: Date()) {
            isCompleted = entry.isCompleted
        } else {
            isCompleted = false
        }
    }
}

// MARK: - Navigation Notification

extension Notification.Name {
    static let navigateToToday = Notification.Name("navigateToToday")
}
