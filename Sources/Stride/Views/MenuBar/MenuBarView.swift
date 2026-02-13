import SwiftUI

/**
 Compact view displayed in the macOS menu bar.
 
 Shows current app name, elapsed session time, and quick actions
 to open the main window or quit the app.
 */
struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                Text("Stride")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            
            VStack(spacing: 12) {
                Text(appState.activeAppName)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(appState.formattedTime)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .monospacedDigit()
            }
            .padding()
            
            Divider()
            
            VStack(spacing: 0) {
                Button("Open Stride") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(MenuBarButtonStyle())
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(MenuBarButtonStyle())
            }
        }
        .frame(width: 220)
    }
}

/**
 Custom button style for menu bar buttons.
 
 Provides consistent styling with hover effects for menu bar actions.
 */
struct MenuBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
    }
}
