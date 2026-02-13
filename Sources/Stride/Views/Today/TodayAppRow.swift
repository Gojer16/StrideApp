import SwiftUI

/**
 Enhanced row component displaying an app's usage for today.
 
 Features:
 - Visual progress bar showing percentage of total time
 - Rank indicator
 - Category color accent
 - Hover state styling
 */
struct TodayAppRow: View {
    let app: AppUsage
    let todayTime: TimeInterval
    let percentage: Double
    let rank: Int
    
    @State private var isHovered = false
    
    private var category: Category {
        app.getCategory()
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(hex: "#C0C0C0") // Silver
        case 3: return Color(hex: "#CD7F32") // Bronze
        default: return .clear
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank indicator
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
            }
            
            // Category indicator
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: category.color).opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: category.color))
            }
            
            // App name and progress bar
            VStack(alignment: .leading, spacing: 8) {
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.08))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: category.color),
                                        Color(hex: category.color).opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(percentage), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Time display
            VStack(alignment: .trailing, spacing: 2) {
                Text(todayTime.formatted())
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color(NSColor.textBackgroundColor).opacity(0.8) : Color(NSColor.textBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.06 : 0.03), radius: isHovered ? 12 : 8, x: 0, y: isHovered ? 6 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: category.color).opacity(isHovered ? 0.2 : 0), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
