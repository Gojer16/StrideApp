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
        
        // End the session in the database (async)
        database.endSession(id: session.id.uuidString)
        
        // Calculate duration
        let duration = Date().timeIntervalSince(session.startTime)
        
        // Update totals (async operations)
        database.updateWindowTime(id: window.id.uuidString, duration: duration)
        database.updateAppTime(id: app.id.uuidString, duration: duration)
        
        // Clear current session state
        currentSession = nil
        currentWindow = nil
        currentApp = nil
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
}
