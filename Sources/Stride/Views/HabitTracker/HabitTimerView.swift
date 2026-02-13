import SwiftUI

/**
 * HabitTimerView - Timer overlay for tracking timer-based habits
 *
 * Features:
 * - Large countdown/up display
 * - Start/pause/stop controls
 * - Visual progress ring
 * - Background timer (continues when minimized)
 */
struct HabitTimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit
    let currentEntry: HabitEntry?
    let onComplete: (Double) -> Void // Returns minutes spent
    
    @State private var elapsedSeconds: Double = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var startTime: Date?
    
    // Dark Forest theme
    private let backgroundColor = Color(hex: "#0F1F17")
    private let accentColor: Color
    
    private var targetSeconds: Double { habit.targetValue * 60 }
    private var progress: Double { min(elapsedSeconds / targetSeconds, 1.0) }
    private var isCompleted: Bool { elapsedSeconds >= targetSeconds }
    
    init(habit: Habit, currentEntry: HabitEntry?, onComplete: @escaping (Double) -> Void) {
        self.habit = habit
        self.currentEntry = currentEntry
        self.onComplete = onComplete
        self.accentColor = Color(hex: habit.color)
        
        // Initialize with existing time if any
        if let entry = currentEntry {
            _elapsedSeconds = State(initialValue: entry.value * 60)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Habit info
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                    
                    Text(habit.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Goal: \(habit.formattedTarget)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
                
                Spacer()
                
                // Timer display with progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 12)
                        .frame(width: 280, height: 280)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [accentColor.opacity(0.8), accentColor],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    // Time display
                    VStack(spacing: 8) {
                        Text(formattedTime(elapsedSeconds))
                            .font(.system(size: 64, weight: .light, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        if isCompleted {
                            Text("Goal Reached!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(accentColor)
                        } else {
                            Text("Remaining: \(formattedTime(max(targetSeconds - elapsedSeconds, 0)))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#808080"))
                        }
                    }
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 32) {
                    // Reset button
                    Button(action: resetTimer) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "#9A9A9A"))
                            }
                            
                            Text("Reset")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#9A9A9A"))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Play/Pause button
                    Button(action: toggleTimer) {
                        ZStack {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 88, height: 88)
                                .shadow(color: accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Save button
                    Button(action: saveAndDismiss) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(accentColor)
                            }
                            
                            Text("Save")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(elapsedSeconds == 0)
                    .opacity(elapsedSeconds == 0 ? 0.5 : 1)
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(40)
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // MARK: - Timer Logic
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedSeconds += 0.1
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        pauseTimer()
        elapsedSeconds = 0
    }
    
    private func saveAndDismiss() {
        pauseTimer()
        let minutes = elapsedSeconds / 60
        onComplete(minutes)
        dismiss()
    }
    
    private func formattedTime(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}