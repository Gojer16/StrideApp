import SwiftUI

/**
 * ModifierHintBanner - Educational tooltip for Option+Click shortcut.
 * 
 * Appears after user has performed 3+ habit increments.
 * Dismissible and never shows again once closed.
 * 
 * Design: Warm Paper aesthetic with subtle animation.
 */
struct ModifierHintBanner: View {
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    private let backgroundColor = Color(hex: "#FFF9E6") // Warm cream
    private let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let accentColor = Color(hex: "#4A7C59") // Stride Moss
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(accentColor)
            
            // Message
            Text("Tip: Hold **Option** while clicking to quickly undo sessions")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)
            
            Spacer()
            
            // Dismiss button
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}
