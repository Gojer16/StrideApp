import SwiftUI

/**
 * Sparkline - A tiny line graph showing usage patterns throughout the day.
 * 
 * **Purpose:**
 * Visualizes hourly usage distribution to reveal patterns like:
 * - Morning deep work (high usage early)
 * - Afternoon communication (high usage late)
 * - Sporadic usage throughout day
 * 
 * **Design:**
 * - Minimal: 60-80px wide, 20px tall
 * - Smooth line with subtle gradient fill
 * - Category-colored to match app
 */
struct Sparkline: View {
    /// Hourly usage data (24 values, one per hour)
    let data: [TimeInterval]
    
    /// Color for the line and fill
    let color: Color
    
    /// Width of the sparkline
    let width: CGFloat = 70
    
    /// Height of the sparkline
    let height: CGFloat = 20
    
    private var normalizedData: [CGFloat] {
        guard !data.isEmpty else { return [] }
        
        let maxValue = data.max() ?? 1
        guard maxValue > 0 else { return data.map { _ in 0 } }
        
        return data.map { CGFloat($0 / maxValue) }
    }
    
    var body: some View {
        Canvas { context, size in
            guard normalizedData.count > 1 else { return }
            
            let stepX = size.width / CGFloat(normalizedData.count - 1)
            
            // Create path for line
            var path = Path()
            for (index, value) in normalizedData.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - (value * size.height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            // Draw filled area under line
            var fillPath = path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()
            
            context.fill(
                fillPath,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.3), color.opacity(0.05)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
            
            // Draw line
            context.stroke(
                path,
                with: .color(color),
                lineWidth: 1.5
            )
        }
        .frame(width: width, height: height)
    }
}
