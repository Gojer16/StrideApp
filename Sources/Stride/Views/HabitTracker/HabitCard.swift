import SwiftUI

/**
 * HabitCard - Interactive card displaying habit information and quick actions
 *
 * Features:
 * - Icon and color customization
 * - Current streak display
 * - Progress indicator based on habit type
 * - Quick completion actions
 * - Tap to view details
 */
struct HabitCard: View {
    let habit: Habit
    let todayEntry: HabitEntry?
    let streak: HabitStreak
    let onTap: () -> Void
    let onToggle: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onStartTimer: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    // Dark Forest theme
    private let backgroundColor = Color(hex: "#1A2820")
    private let cardBackground = Color(hex: "#263328")
    private let accentColor = Color(hex: "#4A7C59")
    
    private var progress: Double {
        guard let entry = todayEntry else { return 0 }
        switch habit.type {
        case .checkbox:
            return entry.isCompleted ? 1.0 : 0.0
        case .timer, .counter:
            return min(entry.value / habit.targetValue, 1.0)
        }
    }
    
    private var isCompleted: Bool {
        progress >= 1.0
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and streak
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: habit.color).opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: habit.color))
                    }
                    
                    Spacer()
                    
                    // Streak badge
                    HabitStreakBadge(
                        streak: streak.currentStreak,
                        isActive: streak.isActive
                    )
                }
                
                // Habit name and target
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(habit.formattedTarget)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
                
                // Progress section
                VStack(spacing: 8) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: habit.color).opacity(0.8),
                                            Color(hex: habit.color)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 6)
                                .animation(.easeOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 6)
                    
                    // Progress text and action buttons
                    HStack {
                        // Today's progress text
                        Text(progressText)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(progressColor)
                        
                        Spacer()
                        
                        // Quick action buttons
                        HStack(spacing: 8) {
                            switch habit.type {
                            case .checkbox:
                                CheckboxButton(
                                    isChecked: isCompleted,
                                    color: Color(hex: habit.color),
                                    action: onToggle
                                )
                                
                            case .counter:
                                HStack(spacing: 4) {
                                    CounterButton(
                                        icon: "minus",
                                        color: Color(hex: habit.color),
                                        action: onDecrement
                                    )
                                    
                                    Text("\(Int(todayEntry?.value ?? 0))")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 30)
                                    
                                    CounterButton(
                                        icon: "plus",
                                        color: Color(hex: habit.color),
                                        action: onIncrement
                                    )
                                }
                                
                            case .timer:
                                if let entry = todayEntry, entry.value > 0 {
                                    // Show time and complete button
                                    HStack(spacing: 8) {
                                        Text(formatTime(entry.value))
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(Color(hex: habit.color))
                                        
                                        if !isCompleted {
                                            TimerButton(
                                                color: Color(hex: habit.color),
                                                action: onStartTimer
                                            )
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color(hex: habit.color))
                                        }
                                    }
                                } else {
                                    TimerButton(
                                        color: Color(hex: habit.color),
                                        action: onStartTimer
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isHovered ? Color(hex: habit.color).opacity(0.3) : Color.white.opacity(0.05),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
    
    private var progressText: String {
        guard let entry = todayEntry else {
            return habit.type == .checkbox ? "Not done" : "0 / \(habit.formattedTarget)"
        }
        
        switch habit.type {
        case .checkbox:
            return entry.isCompleted ? "Done" : "Not done"
        case .timer:
            return "\(formatTime(entry.value)) / \(habit.formattedTarget)"
        case .counter:
            return "\(Int(entry.value)) / \(habit.formattedTarget)"
        }
    }
    
    private var progressColor: Color {
        if isCompleted {
            return Color(hex: habit.color)
        } else {
            return Color(hex: "#808080")
        }
    }
    
    private func formatTime(_ minutes: Double) -> String {
        let hrs = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

/**
 * Checkbox toggle button
 */
struct CheckboxButton: View {
    let isChecked: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isChecked ? color : Color.white.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

/**
 * Counter increment/decrement button
 */
struct CounterButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

/**
 * Timer start button
 */
struct TimerButton: View {
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

/**
 * View extension for press events
 */
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}