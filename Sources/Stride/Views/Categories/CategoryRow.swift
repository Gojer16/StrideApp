import SwiftUI

/**
 * CategoryRow - Row component displaying category information in a list.
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Clean white backgrounds
 * - Soft shadows and borders
 * - Terracotta accents for selected state
 * - Smooth hover interactions
 */
struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    @State private var isHovering = false
    
    private var totalTime: TimeInterval {
        let apps = UsageDatabase.shared.getApplicationsByCategory(categoryId: category.id.uuidString)
        return apps.reduce(0) { $0 + $1.totalTimeSpent }
    }
    
    private var appCount: Int {
        UsageDatabase.shared.getApplicationsByCategory(categoryId: category.id.uuidString).count
    }
    
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: category.color).opacity(0.15),
                                Color(hex: category.color).opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                Color(hex: category.color).opacity(0.25),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: category.color))
                    .symbolRenderingMode(.hierarchical)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(category.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    if category.isDefault {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(secondaryText.opacity(0.5))
                    }
                }
                
                HStack(spacing: 4) {
                    Text("\(appCount) app\(appCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText.opacity(0.5))
                    
                    Text(totalTime.formatted())
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(accentColor.opacity(0.9))
                }
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? accentColor.opacity(0.08) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isSelected ? accentColor.opacity(0.4) : (isHovering ? Color.black.opacity(0.1) : Color.clear),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovering && !isSelected ? Color.black.opacity(0.03) : Color.clear)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
