import SwiftUI

/**
 * BrowserDomainRow - Displays a web domain's usage statistics.
 * 
 * Shows domain name, browser icon, time spent, and percentage of total time.
 * Used in the "Web Activity" section of the Today tab.
 */
struct BrowserDomainRow: View {
    let domain: BrowserDomain
    let totalTime: TimeInterval
    
    @State private var isHovered = false
    
    private var percentage: Double {
        totalTime > 0 ? domain.activeTime / totalTime : 0
    }
    
    private var browserColor: Color {
        // Color based on browser
        if domain.browserApp.lowercased().contains("chrome") {
            return Color(hex: "#4285F4") // Chrome blue
        } else if domain.browserApp.lowercased().contains("safari") {
            return Color(hex: "#006CFF") // Safari blue
        } else if domain.browserApp.lowercased().contains("firefox") {
            return Color(hex: "#FF7139") // Firefox orange
        } else {
            return Color(hex: "#5B7C8C") // Default slate
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // MARK: Icon Section
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(browserColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(browserColor)
            }
            
            // MARK: Details Section
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(domain.domain)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("WEB")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(1)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.03))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(browserColor)
                            .frame(width: geo.size.width * CGFloat(percentage), height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            // MARK: Metrics Section
            VStack(alignment: .trailing, spacing: 2) {
                Text(domain.activeTime.formatted())
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
                .stroke(browserColor.opacity(isHovered ? 0.3 : 0), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}
