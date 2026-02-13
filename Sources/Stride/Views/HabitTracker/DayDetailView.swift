import SwiftUI

/**
 * DayDetailView - Popup for viewing and editing a specific day's habit entry
 *
 * Features:
 * - Shows habit details for selected date
 * - Edit existing entry or add new one
 * - Different controls based on habit type
 * - Delete entry option
 */
struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit
    let date: Date
    let entry: HabitEntry?
    let onSave: (Double, String) -> Void
    let onDelete: () -> Void
    
    @State private var value: Double
    @State private var notes: String
    @State private var isCompleted: Bool
    
    private let backgroundColor = Color(hex: "#0F1F17")
    private let cardBackground = Color(hex: "#1A2820")
    private let accentColor: Color
    
    init(habit: Habit, date: Date, entry: HabitEntry?, onSave: @escaping (Double, String) -> Void, onDelete: @escaping () -> Void) {
        self.habit = habit
        self.date = date
        self.entry = entry
        self.onSave = onSave
        self.onDelete = onDelete
        self.accentColor = Color(hex: habit.color)
        
        if let entry = entry {
            _value = State(initialValue: entry.value)
            _notes = State(initialValue: entry.notes)
            _isCompleted = State(initialValue: entry.isCompleted)
        } else {
            _value = State(initialValue: 0)
            _notes = State(initialValue: "")
            _isCompleted = State(initialValue: false)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Date header
                    dateHeader
                    
                    // Current status
                    statusSection
                    
                    // Value input based on habit type
                    inputSection
                    
                    // Notes
                    notesSection
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtons
                }
                .padding(24)
            }
            .navigationTitle("Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    // MARK: - Sections
    
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(date))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: habit.icon)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                    
                    Text(habit.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                }
            }
            
            Spacer()
            
            if date.isToday {
                Text("TODAY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.15))
                    )
            }
        }
    }
    
    private var statusSection: some View {
        HStack(spacing: 16) {
            StatusCard(
                title: "Current",
                value: currentValueText,
                icon: "circle.fill",
                color: currentValueColor
            )
            
            StatusCard(
                title: "Goal",
                value: habit.formattedTarget,
                icon: "target",
                color: Color(hex: "#808080")
            )
            
            StatusCard(
                title: "Progress",
                value: "\(Int(progress * 100))%",
                icon: "chart.bar.fill",
                color: progress >= 1.0 ? accentColor : Color(hex: "#808080")
            )
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Value")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#808080"))
                .textCase(.uppercase)
            
            switch habit.type {
            case .checkbox:
                Toggle(isOn: $isCompleted) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(isCompleted ? accentColor.opacity(0.2) : Color.white.opacity(0.05))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: isCompleted ? "checkmark" : "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isCompleted ? accentColor : Color(hex: "#808080"))
                        }
                        
                        Text(isCompleted ? "Completed" : "Not completed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isCompleted ? accentColor : Color(hex: "#B3B3B3"))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: accentColor))
                
            case .counter:
                HStack(spacing: 20) {
                    Button(action: { value = max(0, value - 1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(Int(value))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(minWidth: 80)
                    
                    Button(action: { value += 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 20)
                
            case .timer:
                VStack(spacing: 16) {
                    Text("\(Int(value)) minutes")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Slider(value: $value, in: 0...max(habit.targetValue * 2, 60), step: 5)
                        .tint(accentColor)
                    
                    HStack(spacing: 12) {
                        ForEach([5, 10, 15, 30, 60], id: \.self) { mins in
                            Button(action: { value = Double(mins) }) {
                                Text("\(mins)m")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(value == Double(mins) ? .white : accentColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(value == Double(mins) ? accentColor : accentColor.opacity(0.15))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
        )
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#808080"))
                .textCase(.uppercase)
            
            TextEditor(text: $notes)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(height: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                )
                .scrollContentBackground(.hidden)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: saveEntry) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Save Entry")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor)
                )
            }
            .buttonStyle(.plain)
            
            if entry != nil {
                Button(action: { onDelete(); dismiss() }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Entry")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#9C3D2F"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var currentValueText: String {
        switch habit.type {
        case .checkbox:
            return isCompleted ? "Done" : "Not done"
        case .timer:
            return "\(Int(value))m"
        case .counter:
            return "\(Int(value))"
        }
    }
    
    private var currentValueColor: Color {
        switch habit.type {
        case .checkbox:
            return isCompleted ? accentColor : Color(hex: "#808080")
        case .timer, .counter:
            return value >= habit.targetValue ? accentColor : Color(hex: "#808080")
        }
    }
    
    private var progress: Double {
        switch habit.type {
        case .checkbox:
            return isCompleted ? 1.0 : 0.0
        case .timer, .counter:
            return min(value / habit.targetValue, 1.0)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func saveEntry() {
        let finalValue: Double
        switch habit.type {
        case .checkbox:
            finalValue = isCompleted ? 1.0 : 0.0
        case .timer, .counter:
            finalValue = value
        }
        onSave(finalValue, notes)
        dismiss()
    }
}

/**
 * Status card for showing current/goal/progress
 */
struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(color.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(hex: "#808080"))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#263328"))
        )
    }
}
