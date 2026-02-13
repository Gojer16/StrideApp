import Foundation
import AppKit

/**
 Provides window title information using macOS Accessibility APIs.
 
 This class encapsulates all Accessibility API interactions, handling:
 - App element creation
 - Focused window queries
 - Title extraction
 - Error handling for missing permissions or unsupported apps
 
 **Thread Safety:** All methods should be called from the main thread since
 Accessibility APIs are not thread-safe and we publish to UI-bound properties.
 
 **Performance Considerations:**
 - Accessibility API calls are expensive (CPU-intensive)
 - Should be called sparingly (e.g., every 2 seconds, not every frame)
 - Results should be cached when possible
 */
class WindowTitleProvider {
    
    /**
     Retrieves the active window title for a given application.
     
     **Requirements:**
     - User must grant Accessibility permissions to Stride
     - Target app must support Accessibility (some sandboxed apps don't)
     
     **Failure Modes:**
     Returns empty string when:
     - Accessibility permissions are missing
     - App doesn't support Accessibility
     - Focused element isn't a window (e.g., menu bar)
     - App has no focused window
     
     **Type Safety:** Uses `CFGetTypeID()` to validate the window is actually
     an AXUIElement before casting, preventing crashes from unexpected types.
     
     - Parameter app: The running application to query
     - Returns: Window title string, or empty string if unavailable
     */
    func getWindowTitle(for app: NSRunningApplication) -> String {
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        
        // Validate we successfully got a window element
        guard result == .success,
              let window = focusedWindow,
              CFGetTypeID(window) == AXUIElementGetTypeID() else {
            return ""
        }
        
        // Safe to force cast after type validation
        let windowElement = window as! AXUIElement
        
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(
            windowElement,
            kAXTitleAttribute as CFString,
            &titleValue
        )
        
        if titleResult == .success, let title = titleValue {
            return title as? String ?? ""
        }
        
        return ""
    }
}
