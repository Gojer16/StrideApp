import SwiftUI

/**
 * QuickStatCard - A reusable card component displaying a statistic with icon, value, and label.
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Clean white cards with soft shadows
 * - Terracotta/ochre accent colors
 * - Smooth hover effects with subtle elevation
 * - Used in the CurrentSessionView to show quick stats
 */
struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @State private var isHovering = false
    
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.15),
                                color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(color.opacity(0.25), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
            }
            
            // Value
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .monospacedDigit()
            
            // Label
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(secondaryText)
                .tracking(0.5)
        }
        .frame(width: 150)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackground)
                .shadow(
                    color: Color.black.opacity(isHovering ? 0.08 : 0.04),
                    radius: isHovering ? 16 : 10,
                    x: 0,
                    y: isHovering ? 8 : 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    color.opacity(isHovering ? 0.35 : 0.12),
                    lineWidth: isHovering ? 2 : 1
                )
        )
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
