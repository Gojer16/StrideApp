import SwiftUI

/**
 Box component displaying a statistic with icon, value, and label.
 
 Used in app detail sidebars and other places requiring compact stat displays.
 */
struct DetailStatBox: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.textBackgroundColor))
        )
    }
}
