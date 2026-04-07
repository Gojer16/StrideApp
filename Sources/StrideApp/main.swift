import SwiftUI
import StrideLib

/**
 * Stride macOS Application Entry Point
 *
 * This is a thin wrapper that imports the StrideLib library
 * and launches the main app.
 */
@main
struct StrideAppLauncher: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup("Stride") {
            MainWindowView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 750)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView()
                .frame(width: 280, height: 220)
                .environmentObject(appState)
        } label: {
            Label("Stride", systemImage: "eye")
        }
    }
}

/**
 * AppDelegate handles app lifecycle events and system-level configurations.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app has a presence in the Dock
        NSApp.setActivationPolicy(.regular)
    }
}
