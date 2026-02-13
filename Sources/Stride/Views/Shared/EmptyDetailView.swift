import SwiftUI

/**
 Empty state view displayed when no app is selected.
 
 Shows a helpful message prompting the user to select an app from the list.
 */
struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "arrow.left.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.4))
            
            VStack(spacing: 8) {
                Text("Select an App")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
                
                Text("Choose an app from the list to view detailed statistics")
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
