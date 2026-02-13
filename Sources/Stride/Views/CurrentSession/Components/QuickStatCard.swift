import SwiftUI

/**
 * QuickStatCard - A reusable stat component for the Stride Dashboard.
 *
 * **Visual Identity:**
 * Part of the "Ambient Status" design language, these cards use ultra-thin materials
 * and soft shadows to feel lightweight and integrated into the atmospheric background.
 * 
 * **Behaviors:**
 * - Hover elevation: Increases shadow depth and border opacity on mouse-over.
 * - Dynamic color: Icons and borders react to the `currentCategoryColor` passed from the parent.
 */
struct QuickStatCard: View {
    /// SF Symbol name for the icon
    let icon: String
    
    /// The numeric or time value to display
    let value: String
    
    /// Descriptive label for the statistic
    let label: String
    
    /// The accent color (usually the current app's category color)
    let color: Color
    
    @State private var isHovering = false
    
    // MARK: - Constants
    
    private let cardBackground = Color.white.opacity(0.4)
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let secondaryText = Color(red: 0.3, green: 0.3, blue: 0.3)
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: Icon Section
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
            
            // MARK: Data Section
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .monospacedDigit()
                
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(secondaryText.opacity(0.8))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(cardBackground)
                .background(
                    BlurView(style: .hudWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                )
                .shadow(
                    color: Color.black.opacity(isHovering ? 0.08 : 0.04),
                    radius: isHovering ? 20 : 12,
                    x: 0,
                    y: isHovering ? 10 : 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    color.opacity(isHovering ? 0.4 : 0.15),
                    lineWidth: isHovering ? 2 : 1
                )
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
