import Foundation

/**
 Manages usage tracking sessions for applications and windows.
 
 This class handles the lifecycle of tracking sessions:
 - Starting new sessions when app/window changes
 - Ending sessions and persisting data to database
 - Tracking current session state
 
 **Session Lifecycle:**
 ```
 User switches to Safari/YouTube
        ↓
 startNewSession(appName: "Safari", windowTitle: "YouTube")
        ↓
 [Session active - timer running]
        ↓
 User switches to Xcode
        ↓
 endCurrentSession()  // Saves Safari/YouTube time
        ↓
 startNewSession(appName: "Xcode", ...)
 ```
 
 **Database Integration:**
 All database operations are async and thread-safe (see UsageDatabase).
 Time calculations happen synchronously, but persistence is async.
 
 **Thread Safety:** This class assumes it's used from a single thread
 (typically main thread via AppState).
 */
class SessionManager {
    
    // MARK: - Current Session State
    
    /// Active usage session tracking time for current app+window
    private(set) var currentSession: UsageSession?
    
    /// Current app being tracked
    private(set) var currentApp: AppUsage?
    
    /// Current window being tracked
    private(set) var currentWindow: WindowUsage?
    
    /// Whether the current session is paused due to idle detection
    private(set) var isPaused: Bool = false
    
    /// Accumulated passive time for current session
    private var passiveTimeAccumulated: TimeInterval = 0
    
    /// Time when session was paused (for calculating passive duration)
    private var pauseStartTime: Date?
    
    /// Reference to database for persistence
    private let database: UsageDatabase
    
    // MARK: - Initialization
    
    init(database: UsageDatabase = .shared) {
        self.database = database
    }
    
    // MARK: - Session Control
    
    /**
     Starts a new usage tracking session.
     
     This method:
     1. Gets or creates the AppUsage record
     2. Gets or creates the WindowUsage record
     3. Increments visit counts
     4. Creates a new UsageSession
     
     **Note:** Should be called AFTER ending any existing session.
     
     - Parameters:
        - appName: Name of the application (e.g., "Safari")
        - windowTitle: Title of the window (may be empty)
     */
    func startNewSession(appName: String, windowTitle: String) {
        // Get existing app or create new one
        if let existingApp = database.getApplication(name: appName) {
            database.incrementAppVisits(name: appName)
            currentApp = existingApp
        } else {
            currentApp = database.getOrCreateApplication(name: appName)
        }
        
        guard let app = currentApp else { return }
        
        // Get existing window or create new one
        if let existingWindow = database.getWindow(appId: app.id.uuidString, title: windowTitle) {
            database.incrementWindowVisits(id: existingWindow.id.uuidString)
            currentWindow = existingWindow
        } else {
            currentWindow = database.getOrCreateWindow(appId: app.id.uuidString, title: windowTitle)
        }
        
        // Create session to track time for this app+window
        if let window = currentWindow {
            currentSession = database.createSession(windowId: window.id.uuidString)
        }
    }
    
    /**
     Ends the current session and persists data to database.
     
     Calculates session duration and updates:
     - Session end time and duration (async)
     - Window total time spent (async)
     - App total time spent (async)
     
     **Idempotent:** Safe to call even if no session is active.
     */
    func endCurrentSession() {
        guard let session = currentSession,
              let window = currentWindow,
              let app = currentApp else {
            return
        }
        
        // If session is paused, accumulate final passive time
        if isPaused, let pauseStart = pauseStartTime {
            passiveTimeAccumulated += Date().timeIntervalSince(pauseStart)
        }
        
        // End the session in the database (async)
        database.endSession(id: session.id.uuidString, passiveDuration: passiveTimeAccumulated)
        
        // Calculate active duration (total - passive)
        let totalDuration = Date().timeIntervalSince(session.startTime)
        let activeDuration = totalDuration - passiveTimeAccumulated
        
        // Update totals with active time only (async operations)
        database.updateWindowTime(id: window.id.uuidString, duration: activeDuration)
        database.updateAppTime(id: app.id.uuidString, duration: activeDuration)
        
        // Clear current session state
        currentSession = nil
        currentWindow = nil
        currentApp = nil
        isPaused = false
        passiveTimeAccumulated = 0
        pauseStartTime = nil
    }
    
    // MARK: - Pause/Resume Control
    
    /**
     Pauses the current session due to idle detection.
     
     Marks the session as paused and records the pause start time.
     Passive time will be accumulated when session resumes or ends.
     */
    func pauseSession() {
        guard currentSession != nil, !isPaused else { return }
        
        isPaused = true
        pauseStartTime = Date()
    }
    
    /**
     Resumes the current session after idle period.
     
     Accumulates the passive time and marks session as active again.
     The same session continues (no new session created).
     */
    func resumeSession() {
        guard currentSession != nil, isPaused, let pauseStart = pauseStartTime else {
            return
        }
        
        // Accumulate passive time
        let passiveDuration = Date().timeIntervalSince(pauseStart)
        passiveTimeAccumulated += passiveDuration
        
        // Resume active tracking
        isPaused = false
        pauseStartTime = nil
    }
    
    // MARK: - Session Queries
    
    /// Returns true if a session is currently active
    var hasActiveSession: Bool {
        return currentSession != nil
    }
    
    /// Returns the start time of the current session, or nil if no session
    var currentSessionStartTime: Date? {
        return currentSession?.startTime
    }
    
    /// Returns the name of the currently tracked app, or nil
    var currentAppName: String? {
        return currentApp?.name
    }
    
    /// Returns the title of the currently tracked window, or nil
    var currentWindowTitle: String? {
        return currentWindow?.title
    }
    
    /// Returns the active time for the current session (excluding passive time)
    var currentActiveTime: TimeInterval? {
        guard let session = currentSession else { return nil }
        let totalTime = Date().timeIntervalSince(session.startTime)
        return totalTime - passiveTimeAccumulated
    }
    
    /// Returns the passive time accumulated in the current session
    var currentPassiveTime: TimeInterval {
        var passive = passiveTimeAccumulated
        // If currently paused, add ongoing passive time
        if isPaused, let pauseStart = pauseStartTime {
            passive += Date().timeIntervalSince(pauseStart)
        }
        return passive
    }
}
