import SwiftUI

/**
 * AppGridCard - Card component displaying app information in a grid layout.
 *
 * Aesthetic: Warm Paper/Editorial Light
 * - Clean white cards with soft shadows
 * - Category-colored icons with borders
 * - Smooth hover effects
 *
 * Shows app icon, name, category, visits, and total time spent.
 */
struct AppGridCard: View {
    let app: AppUsage
    @State private var isHovered = false
    
    private let cardBackground = Color.white
    private let textColor = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let secondaryText = Color(red: 0.38, green: 0.38, blue: 0.38)
    private let accentColor = Color(red: 0.78, green: 0.357, blue: 0.224)
    
    var body: some View {
        let category = app.getCategory()
        
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: category.color).opacity(0.12))
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(hex: category.color).opacity(0.25), lineWidth: 1)
                    )
                
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color(hex: category.color))
            }
            
            // App info
            VStack(alignment: .leading, spacing: 5) {
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(textColor)
                
                HStack(spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText.opacity(0.5))
                    
                    Text("\(app.visitCount) visit\(app.visitCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText)
                }
            }
            
            Spacer()
            
            // Time stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(app.formattedTotalTime())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                let todayTime = UsageDatabase.shared.getTodayTime(for: app.id.uuidString)
                if todayTime > 0 {
                    Text("+\(todayTime.formatted()) today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBackground)
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.06 : 0.03),
                    radius: isHovered ? 12 : 8,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isHovered ? Color(hex: category.color).opacity(0.25) : Color.black.opacity(0.06),
                            lineWidth: isHovered ? 1.5 : 1
                        )
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
