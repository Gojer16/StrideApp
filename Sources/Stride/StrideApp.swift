import SwiftUI
import AppKit
import UserNotifications

/**
 * Stride Application
 * 
 * A macOS productivity tool that passively tracks active application and window usage time.
 * Focused on a "Live" atmospheric experience that gives users real-time feedback
 * about their digital behavior.
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
 * AppDelegate handles app lifecycle events and system-level configurations.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app has a presence in the Dock
        NSApp.setActivationPolicy(.regular)
        
        // Request notification permissions for habit reminders
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        // Feature disabled for Swift Package Manager builds as it requires a bundle identifier
        print("Notification permissions: Feature disabled in SPM build")
    }
}

// MARK: - App State

/**
 * AppState - Central Coordinator for the Stride Application.
 * 
 * Acts as the "Single Source of Truth" for the entire application, coordinating
 * between the passive monitor, the session manager, and the UI layers.
 * 
 * **Responsibilities:**
 * 1. **Data Coordination**: Aggregates usage data for the "Live" tab.
 * 2. **Ambient UI**: Manages the `currentCategoryColor` that drives the atmospheric background.
 * 3. **Session State**: Publishes real-time timer updates and active app info.
 * 4. **History**: Maintains a list of recent applications for contextual awareness.
 */
class AppState: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared singleton instance for the entire app life
    static let shared = AppState()
    
    // MARK: - Services
    
    /// Low-level monitor that listens to system-wide app activation notifications
    private let appMonitor: AppMonitor
    
    /// High-level manager that translates app/window changes into usage sessions
    private let sessionManager: SessionManager
    
    // MARK: - Published Properties (UI-bound)
    
    /// Name of the application currently in the foreground (e.g., "Xcode")
    @Published var activeAppName: String = "Unknown"
    
    /// Title of the frontmost window (e.g., "StrideApp.swift")
    @Published var activeWindowTitle: String = ""
    
    /// Total duration of the current session in seconds
    @Published var elapsedTime: TimeInterval = 0
    
    /// String representation of the elapsed time (e.g., "1h 05m 30s")
    @Published var formattedTime: String = "0s"
    
    /// A small collection of the user's most recently used apps for the "Recent Context" UI
    @Published var recentApps: [AppUsage] = []
    
    /// The primary color of the active app's category (used for Ambient Status UI)
    @Published var currentCategoryColor: Color = Color(red: 0.78, green: 0.357, blue: 0.224)
    
    // MARK: - Internal State
    
    /// The exact moment the current session began
    private var appStartTime: Date?
    
    /// Preserved window title to handle temporary Accessibility API failures
    private var lastValidWindowTitle: String = ""
    
    // MARK: - Initialization
    
    init(appMonitor: AppMonitor = AppMonitor(),
         sessionManager: SessionManager = SessionManager()) {
        self.appMonitor = appMonitor
        self.sessionManager = sessionManager
        
        // Set up the app monitor to notify us on changes
        self.appMonitor.delegate = self
        
        // Start the passive tracking loop
        self.appMonitor.startMonitoring()
        
        // Perform initial data fetch for the Live tab
        refreshRecentApps()
        
        // Set the initial ambient color based on the current foreground app
        if let appUsage = UsageDatabase.shared.getApplication(name: activeAppName) {
            self.currentCategoryColor = Color(hex: appUsage.getCategory().color)
        }
    }
    
    deinit {
        appMonitor.stopMonitoring()
    }
    
    // MARK: - Logic & Management
    
    /**
     * Updates the local list of recently used apps from the database.
     * Called whenever a new session starts to keep the "Live" tab fresh.
     */
    func refreshRecentApps() {
        let apps = UsageDatabase.shared.getRecentApplications(limit: 5)
        DispatchQueue.main.async {
            self.recentApps = apps
        }
    }
    
    // MARK: - Computed Statistics
    
    /// Returns the total number of window switches/visits today across all apps
    var totalVisitsToday: Int {
        let apps = UsageDatabase.shared.getAllApplications()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return apps.filter { $0.lastSeen >= startOfDay }.reduce(0) { $0 + $1.visitCount }
    }
    
    /// Returns the cumulative time spent on the computer today
    var totalTimeToday: TimeInterval {
        let apps = UsageDatabase.shared.getAllApplications()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return apps.filter { $0.lastSeen >= startOfDay }.reduce(0) { $0 + $1.totalTimeSpent }
    }
    
    // MARK: - Session Management
    
    /**
     * Starts a new usage session.
     * 
     * Handles the transition between two contexts:
     * 1. Closes the current session in the database.
     * 2. Resolves the category and ambient color for the new app.
     * 3. Opens a new session and resets the UI timer.
     */
    private func startSession(appName: String, windowTitle: String) {
        // Persist the end of the previous session
        sessionManager.endCurrentSession()
        
        // Handle accessibility edge cases for window titles
        if !windowTitle.isEmpty {
            lastValidWindowTitle = windowTitle
        }
        let sessionTitle = windowTitle.isEmpty ? lastValidWindowTitle : windowTitle
        
        // Record the new session
        sessionManager.startNewSession(appName: appName, windowTitle: sessionTitle)
        
        // Update Published state for the UI
        activeAppName = appName
        activeWindowTitle = sessionTitle
        
        // Update Ambient Status color
        if let appUsage = UsageDatabase.shared.getApplication(name: appName) {
            let category = appUsage.getCategory()
            self.currentCategoryColor = Color(hex: category.color)
        } else {
            // Default to Stride's primary brand color for unknown apps
            self.currentCategoryColor = Color(red: 0.78, green: 0.357, blue: 0.224)
        }
        
        // Reset timer
        appStartTime = Date()
        elapsedTime = 0
        formattedTime = "0s"
        
        // Update history sidebar/recent context
        refreshRecentApps()
    }
    
    /**
     * Updates the elapsed time display string.
     * Called every second by the AppMonitor ticker.
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

// MARK: - AppMonitorDelegate Integration

extension AppState: AppMonitorDelegate {
    
    /**
     * Responds to the OS notifying us that a new application has been focused.
     */
    func appMonitor(_ monitor: AppMonitor, didDetectAppChange app: NSRunningApplication) {
        DispatchQueue.main.async {
            let appName = app.localizedName ?? "Unknown"
            let windowTitle = self.appMonitor.getCurrentWindowTitle()
            
            // Deduplicate notifications to prevent rapid session restarts
            guard appName != self.activeAppName || windowTitle != self.activeWindowTitle else {
                return
            }
            
            self.startSession(appName: appName, windowTitle: windowTitle)
        }
    }
    
    /**
     * Responds to changes in the window title within the same active application.
     */
    func appMonitor(_ monitor: AppMonitor, didDetectWindowChange title: String) {
        DispatchQueue.main.async {
            // Only start a new session if the window title actually changed and is valid
            guard !title.isEmpty,
                  title != self.lastValidWindowTitle,
                  let appName = self.appMonitor.currentApp?.localizedName else {
                return
            }
            
            self.startSession(appName: appName, windowTitle: title)
        }
    }
    
    /**
     * Tick event received every second from the monitor's internal timer.
     */
    func appMonitorDidUpdateElapsedTime(_ monitor: AppMonitor) {
        DispatchQueue.main.async {
            self.updateElapsedTime()
        }
    }
    
    /**
     * Responds to idle state changes detected by the monitor.
     * 
     * When user becomes idle (no keyboard/mouse input for threshold duration),
     * the current session is paused. When user returns, session resumes.
     */
    func appMonitor(_ monitor: AppMonitor, didDetectIdleStateChange isIdle: Bool) {
        DispatchQueue.main.async {
            if isIdle {
                self.sessionManager.pauseSession()
            } else {
                self.sessionManager.resumeSession()
            }
        }
    }
}
