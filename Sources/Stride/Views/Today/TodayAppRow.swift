import SwiftUI

/**
 * TodayAppRow - A refined row component for the Today Summary.
 * 
 * **Role:**
 * Displays a single application's contribution to the day's total active time.
 * 
 * **Features:**
 * 1. Category Badge: Shows the icon and color of the assigned label.
 * 2. Smart Progress: A minimal bar showing usage relative to other apps.
 * 3. Editorial Metadata: Displays the category name in a high-tracking, small-caps style.
 * 4. Interactive Feedback: Subtle scale and shadow shifts on hover.
 */
struct TodayAppRow: View {
    /// The application data model
    let app: AppUsage
    
    /// Pre-calculated active time for today
    let todayTime: TimeInterval
    
    /// Percentage of the total active time for today
    let percentage: Double
    
    /// Ranking position (1-5)
    let rank: Int
    
    /// Hourly usage data for sparkline (optional, only for top 3)
    let hourlyUsage: [TimeInterval]
    
    @State private var isHovered = false
    
    private var category: Category {
        app.getCategory()
    }
    
    private var categoryColor: Color {
        Color(hex: category.color)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // MARK: Icon Section
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(categoryColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(categoryColor)
            }
            
            // MARK: Details Section
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(app.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text(category.name.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(1)
                    
                    // Sparkline for top 3 apps
                    if rank <= 3 && !hourlyUsage.isEmpty {
                        Sparkline(data: hourlyUsage, color: categoryColor)
                            .opacity(0.8)
                    }
                }
                
                // Secondary visualization of usage relative to total
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.03))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(categoryColor)
                            .frame(width: geo.size.width * CGFloat(percentage), height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            // MARK: Metrics Section
            VStack(alignment: .trailing, spacing: 2) {
                Text(todayTime.formatted())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHovered ? Color.white : Color.white.opacity(0.5))
                .shadow(color: .black.opacity(isHovered ? 0.05 : 0.02), radius: isHovered ? 15 : 5, x: 0, y: isHovered ? 5 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(categoryColor.opacity(isHovered ? 0.3 : 0), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}
