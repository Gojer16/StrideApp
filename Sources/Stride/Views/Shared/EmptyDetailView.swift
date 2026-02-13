import SwiftUI

/**
 * EmptyDetailView - A reusable placeholder view for empty states in detail sidebars.
 * 
 * Aesthetic: Warm Paper/Editorial Light
 * - Soft secondary typography
 * - Large, semi-transparent icons
 * - Clean background integration
 */
struct EmptyDetailView: View {
    let title: String
    let subtitle: String
    let icon: String
    
    init(title: String = "Select an Item", 
         subtitle: String = "Choose an item from the list to view details.", 
         icon: String = "arrow.left.circle") {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.4))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
