import SwiftUI
import AppKit

/**
 Compact view displayed in the macOS menu bar.

 Adds quick controls to enable/disable tracking, open logs, open settings,
 and quit the app.
 */
struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 10) {
                Text(appState.activeAppName)
                    .font(.system(size: 15, weight: .semibold))

                Text(appState.formattedTime)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .monospacedDigit()
            }
            .padding()

            Divider()

            VStack(spacing: 0) {
                Button("Open Logs Folder") {
                    openLogsFolder()
                }
                .buttonStyle(MenuBarButtonStyle())

                Button("Open Settings") {
                    openSettings()
                }
                .buttonStyle(MenuBarButtonStyle())

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(MenuBarButtonStyle())
            }
        }
        .frame(width: 260)
    }

    private var header: some View {
        HStack {
            Image(systemName: "eye.fill")
                .foregroundColor(.blue)
            Text("Stride")
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }

    private func openLogsFolder() {
        guard let url = ActivityLogger.applicationSupportStrideFolderURL() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        // Minimal: just bring the main window forward; user can click “Settings” in the sidebar.
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
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
