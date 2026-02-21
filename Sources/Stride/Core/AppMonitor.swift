import Foundation
import AppKit

/**
 Protocol for receiving app/window change notifications.
 
 Implement this protocol to receive callbacks when the user switches
 apps or windows. Used by AppState to coordinate with AppMonitor.
 */
protocol AppMonitorDelegate: AnyObject {
    /// Called when user switches to a different application
    func appMonitor(_ monitor: AppMonitor, didDetectAppChange app: NSRunningApplication)
    
    /// Called when window title changes within the same application
    func appMonitor(_ monitor: AppMonitor, didDetectWindowChange title: String)
    
    /// Called every second for elapsed time updates
    func appMonitorDidUpdateElapsedTime(_ monitor: AppMonitor)
    
    /// Called when idle state changes (user becomes idle or returns from idle)
    func appMonitor(_ monitor: AppMonitor, didDetectIdleStateChange isIdle: Bool)
}

/**
 Monitors app and window changes using notifications and polling.
 
 This class uses a dual-strategy approach for efficient monitoring:
 
 **Strategy 1: App Changes (Event-Driven)**
 - Uses `NSWorkspace.didActivateApplicationNotification`
 - Instant notification when user switches apps
 - No polling overhead
 
 **Strategy 2: Window Changes (Polling)**
 - Uses 2-second timer to check window titles
 - Necessary because macOS doesn't notify about window switches
   within the same app (e.g., switching tabs in Safari)
 - Longer interval (2s) to minimize CPU/Accessibility API usage
 
 **Performance Optimization:**
 - Original implementation polled every 0.5s (too expensive)
 - Current implementation: event-driven for apps, 2s polling for windows
 - Significantly reduces CPU usage and battery drain
 */
class AppMonitor {
    
    // MARK: - Properties
    
    weak var delegate: AppMonitorDelegate?
    
    /// Provider for getting window titles
    private let windowTitleProvider: WindowTitleProvider
    
    /// Detector for system idle time
    private let idleDetector: IdleDetector
    
    /// Current app being monitored
    private(set) var currentApp: NSRunningApplication?
    
    /// Last known window title (for change detection)
    private var lastWindowTitle: String = ""
    
    /// Last known idle state (for change detection)
    private var wasIdle: Bool = false
    
    // MARK: - Timers
    
    /// Timer for checking window title changes (every 2 seconds)
    private var windowCheckTimer: Timer?
    
    /// Timer for elapsed time display updates (every 1 second)
    private var elapsedTimeTimer: Timer?
    
    // MARK: - Constants
    
    private enum Constants {
        static let windowCheckInterval: TimeInterval = 2.0
        static let elapsedTimeInterval: TimeInterval = 1.0
    }
    
    // MARK: - Initialization
    
    init(windowTitleProvider: WindowTitleProvider = WindowTitleProvider(),
         idleDetector: IdleDetector = IdleDetector()) {
        self.windowTitleProvider = windowTitleProvider
        self.idleDetector = idleDetector
    }
    
    // MARK: - Lifecycle
    
    /**
     Starts monitoring app and window changes.
     
     Sets up:
     1. Notification observer for app activation
     2. Timer for window title polling
     3. Timer for elapsed time updates
     
     **Must be called before using the monitor.**
     */
    func startMonitoring() {
        // Listen for app activation changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Poll for window title changes every 2 seconds
        windowCheckTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.windowCheckInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkWindowTitleChange()
        }
        
        // Update elapsed time every second
        elapsedTimeTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.elapsedTimeInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.appMonitorDidUpdateElapsedTime(self)
        }
        
        // Trigger initial app detection
        appDidActivate()
    }
    
    /**
     Stops monitoring and cleans up resources.
     
     Removes notification observers and invalidates timers.
     **Must be called to prevent memory leaks.**
     */
    func stopMonitoring() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        windowCheckTimer?.invalidate()
        elapsedTimeTimer?.invalidate()
        windowCheckTimer = nil
        elapsedTimeTimer = nil
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - App Change Detection
    
    /**
     Handles app activation notification.
     
     Called when user switches to a different application.
     Notifies delegate of the app change.
     */
    @objc private func appDidActivate() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        
        currentApp = app
        
        // Reset window tracking for new app
        lastWindowTitle = ""
        
        // Notify delegate
        delegate?.appMonitor(self, didDetectAppChange: app)
    }
    
    // MARK: - Window Change Detection
    
    /**
     Checks for window title changes within the current app.
     
     Called every 2 seconds by the timer. Only notifies delegate
     if the window title actually changed.
     
     **Note:** This is called frequently, so it should be efficient.
     The actual Accessibility API call happens in WindowTitleProvider.
     */
    private func checkWindowTitleChange() {
        guard let app = currentApp else { return }
        
        let newWindowTitle = windowTitleProvider.getWindowTitle(for: app)
        
        // Skip empty titles - don't report changes for failed accessibility calls
        guard !newWindowTitle.isEmpty else { return }
        
        // Only notify if title actually changed
        guard newWindowTitle != lastWindowTitle else { return }
        
        lastWindowTitle = newWindowTitle
        delegate?.appMonitor(self, didDetectWindowChange: newWindowTitle)
        
        // Also check idle state during window check (piggyback on existing timer)
        checkIdleState()
    }
    
    /**
     Checks if the system is idle and notifies delegate of state changes.
     
     Called every 2 seconds during window title check. Only notifies
     delegate when idle state actually changes (active → idle or idle → active).
     */
    private func checkIdleState() {
        let threshold = UserPreferences.shared.idleThreshold
        let isIdle = idleDetector.isSystemIdle(threshold: threshold)
        
        // Only notify if state changed
        guard isIdle != wasIdle else { return }
        
        wasIdle = isIdle
        delegate?.appMonitor(self, didDetectIdleStateChange: isIdle)
    }
    
    /**
     Gets the current window title for the active app.
     
     Convenience method that delegates to WindowTitleProvider.
     
     - Returns: Current window title, or empty string if unavailable
     */
    func getCurrentWindowTitle() -> String {
        guard let app = currentApp else { return "" }
        return windowTitleProvider.getWindowTitle(for: app)
    }
}
