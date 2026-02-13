import SwiftUI

/**
 Row component displaying an information item with icon, label, and value.
 
 Used in usage history sections and other places requiring label-value pairs.
 */
struct DetailInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
        }
    }
}
