import SwiftUI

/**
 * HabitStreakBadge - Displays streak count with animated flame
 *
 * Visual Features:
 * - Animated flame icon that pulses with intensity based on streak length
 * - Gradient background that shifts from cool to hot colors
 * - Count display with typography that emphasizes the number
 * - Subtle glow effect for active streaks
 */
struct HabitStreakBadge: View {
    let streak: Int
    let isActive: Bool
    
    @State private var isPulsing = false
    @State private var flameScale: CGFloat = 1.0
    
    // Dark Forest theme colors
    private let flameColor = Color(hex: "#D4A853") // Amber gold
    private let coolStreakColor = Color(hex: "#4A7C59") // Moss green
    private let warmStreakColor = Color(hex: "#C75B39") // Terracotta
    private let hotStreakColor = Color(hex: "#D4A853") // Amber
    
    var body: some View {
        HStack(spacing: 4) {
            // Animated flame icon
            ZStack {
                // Glow effect for active streaks
                if isActive && streak > 0 {
                    Circle()
                        .fill(flameColor.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0.6 : 0.3)
                }
                
                Image(systemName: streak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(flameColor)
                    .scaleEffect(flameScale)
            }
            .frame(width: 16, height: 16)
            
            // Streak count
            Text("\(streak)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(backgroundColor.opacity(0.15))
        )
        .onAppear {
            if isActive && streak > 0 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    flameScale = 1.15
                }
            }
        }
    }
    
    // Dynamic text color based on streak length
    private var textColor: Color {
        if streak == 0 {
            return Color(hex: "#666666")
        } else if streak < 7 {
            return coolStreakColor
        } else if streak < 30 {
            return warmStreakColor
        } else {
            return hotStreakColor
        }
    }
    
    // Dynamic background color based on streak length
    private var backgroundColor: Color {
        if streak == 0 {
            return Color(hex: "#4D4D4D")
        } else if streak < 7 {
            return coolStreakColor
        } else if streak < 30 {
            return warmStreakColor
        } else {
            return hotStreakColor
        }
    }
}

/**
 * HabitStreakIndicator - Larger streak display for detail views
 */
struct HabitStreakIndicator: View {
    let currentStreak: Int
    let longestStreak: Int
    
    @State private var isAnimating = false
    
    private let backgroundColor = Color(hex: "#0F1F17") // Deep forest
    private let flameColor = Color(hex: "#D4A853") // Amber gold
    
    var body: some View {
        HStack(spacing: 24) {
            // Current streak
            VStack(spacing: 8) {
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(flameColor.opacity(0.1 - Double(i) * 0.03), lineWidth: 1)
                            .frame(width: 80 + CGFloat(i * 20), height: 80 + CGFloat(i * 20))
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .opacity(isAnimating ? 0.8 : 0.4)
                    }
                    
                    // Main circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    flameColor.opacity(0.2),
                                    flameColor.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    // Flame icon
                    Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(flameColor)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                .frame(height: 80)
                
                VStack(spacing: 2) {
                    Text("\(currentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Current Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
            }
            
            Divider()
                .frame(height: 100)
                .background(Color.white.opacity(0.1))
            
            // Longest streak
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: "#D4A853"))
                }
                .frame(height: 60)
                
                VStack(spacing: 2) {
                    Text("\(longestStreak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Best Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

