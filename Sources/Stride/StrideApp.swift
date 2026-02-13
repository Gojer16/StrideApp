import SwiftUI
import AppKit
import UserNotifications

/**
 Stride Application
 
 A macOS app that tracks active application and window usage time.
 Uses macOS Accessibility APIs and NSWorkspace notifications to detect
 app/window changes with minimal CPU impact.
 
 **Architecture:**
 The app follows a service-oriented architecture with clear separation of concerns:
 
 - **AppState**: Coordinator that manages UI state and orchestrates services
 - **AppMonitor**: Detects app/window changes via notifications and polling
 - **SessionManager**: Manages usage tracking session lifecycle
 - **WindowTitleProvider**: Retrieves window titles via Accessibility APIs
 - **UsageDatabase**: Thread-safe persistence layer
 */
@main
struct StrideApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup("Stride") {
            MainWindowView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 650)
        .windowResizability(.contentSize)
        
        MenuBarExtra("Stride", systemImage: "eye") {
            MenuBarView()
                .frame(width: 280, height: 180)
                .environmentObject(appState)
        }
    }
}

/**
 AppDelegate handles app lifecycle events.
  
 Currently ensures the app shows in the Dock (regular activation policy)
 and requests notification permissions for habit reminders.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        // Request notification permissions for habit reminders
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        // UserNotifications require proper app bundle configuration
        // This feature is disabled for Swift Package Manager builds
        // Notifications can be enabled when building with Xcode
        print("Notification permissions: Feature disabled in SPM build")
    }
}

// MARK: - App State

/**
 AppState coordinates the application's tracking functionality.
 
 Acts as the central coordinator between:
 - **AppMonitor**: Receives app/window change callbacks
 - **SessionManager**: Manages session lifecycle
 - **UI**: Publishes state for SwiftUI views
 
 **Responsibilities:**
 1. Delegates app/window detection to AppMonitor
 2. Delegates session management to SessionManager
 3. Tracks last valid window title (for accessibility failure recovery)
 4. Calculates elapsed time for UI display
 5. Provides computed statistics for views
 
 **Architecture Benefits:**
 - Single responsibility: AppState focuses on coordination, not implementation
 - Services are testable independently
 - Easy to swap implementations (e.g., mock monitor for testing)
 - Clear separation between detection, tracking, and persistence
 */
class AppState: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared singleton instance
    static let shared = AppState()
    
    // MARK: - Services
    
    /// Monitors app and window changes
    private let appMonitor: AppMonitor
    
    /// Manages usage tracking sessions
    private let sessionManager: SessionManager
    
    // MARK: - Published Properties (UI-bound)
    
    /// Currently active application name
    @Published var activeAppName: String = "Unknown"
    
    /// Current window title
    @Published var activeWindowTitle: String = ""
    
    /// Elapsed time in current session (in seconds)
    @Published var elapsedTime: TimeInterval = 0
    
    /// Formatted elapsed time for display
    @Published var formattedTime: String = "0s"
    
    // MARK: - State
    
    /// When the current app/window session started
    private var appStartTime: Date?
    
    /**
     Last *valid* (non-empty) window title.
     
     Preserved across accessibility failures to prevent artificial
     session restarts when APIs temporarily return empty strings.
     */
    private var lastValidWindowTitle: String = ""
    
    // MARK: - Initialization
    
    init(appMonitor: AppMonitor = AppMonitor(),
         sessionManager: SessionManager = SessionManager()) {
        self.appMonitor = appMonitor
        self.sessionManager = sessionManager
        
        // Set up delegation
        self.appMonitor.delegate = self
        
        // Start monitoring
        self.appMonitor.startMonitoring()
    }
    
    deinit {
        appMonitor.stopMonitoring()
    }
    
    // MARK: - Computed Statistics
    
    /// Total number of app/window visits today
    var totalVisitsToday: Int {
        let apps = UsageDatabase.shared.getAllApplications()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return apps.filter { $0.lastSeen >= startOfDay }.reduce(0) { $0 + $1.visitCount }
    }
    
    /// Total time spent across all apps today
    var totalTimeToday: TimeInterval {
        let apps = UsageDatabase.shared.getAllApplications()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return apps.filter { $0.lastSeen >= startOfDay }.reduce(0) { $0 + $1.totalTimeSpent }
    }
    
    // MARK: - Session Management
    
    /**
     Starts a new tracking session for the given app and window.
     
     Ends any existing session first, then starts a new one.
     Updates UI state and resets elapsed time.
     
     - Parameters:
        - appName: Name of the active application
        - windowTitle: Title of the active window
     */
    private func startSession(appName: String, windowTitle: String) {
        // End existing session if any
        sessionManager.endCurrentSession()
        
        // Track valid window title
        if !windowTitle.isEmpty {
            lastValidWindowTitle = windowTitle
        }
        
        // Use last valid title if current is empty
        let sessionTitle = windowTitle.isEmpty ? lastValidWindowTitle : windowTitle
        
        // Start new session
        sessionManager.startNewSession(appName: appName, windowTitle: sessionTitle)
        
        // Update UI state
        activeAppName = appName
        activeWindowTitle = sessionTitle
        
        // Reset elapsed time
        appStartTime = Date()
        elapsedTime = 0
        formattedTime = "0s"
    }
    
    /**
     Updates the elapsed time display.
     
     Called every second by AppMonitor. Formats time as:
     - "Xs" (seconds only)
     - "Xm Xs" (minutes and seconds)
     - "Xh Xm Xs" (hours, minutes, seconds)
     */
    private func updateElapsedTime() {
        guard let startTime = appStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        self.elapsedTime = elapsed
        
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            formattedTime = "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            formattedTime = "\(minutes)m \(seconds)s"
        } else {
            formattedTime = "\(seconds)s"
        }
    }
}

// MARK: - AppMonitorDelegate

extension AppState: AppMonitorDelegate {
    
    /**
     Called when user switches to a different application.
     
     Always starts a new session for the new app.
     */
    func appMonitor(_ monitor: AppMonitor, didDetectAppChange app: NSRunningApplication) {
        DispatchQueue.main.async {
            let appName = app.localizedName ?? "Unknown"
            let windowTitle = self.appMonitor.getCurrentWindowTitle()
            
            // Only update if actually changed (prevents duplicates)
            guard appName != self.activeAppName || windowTitle != self.activeWindowTitle else {
                return
            }
            
            self.startSession(appName: appName, windowTitle: windowTitle)
        }
    }
    
    /**
     Called when window title changes within the same application.
     
     Starts a new session only if this is a *real* change (not empty,
     not same as last valid title).
     */
    func appMonitor(_ monitor: AppMonitor, didDetectWindowChange title: String) {
        DispatchQueue.main.async {
            // Guard against empty titles and duplicate changes
            guard !title.isEmpty,
                  title != self.lastValidWindowTitle,
                  let appName = self.appMonitor.currentApp?.localizedName else {
                return
            }
            
            self.startSession(appName: appName, windowTitle: title)
        }
    }
    
    /// Called every second to update elapsed time display
    func appMonitorDidUpdateElapsedTime(_ monitor: AppMonitor) {
        DispatchQueue.main.async {
            self.updateElapsedTime()
        }
    }
}
