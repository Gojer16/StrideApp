import Foundation
import IOKit

/**
 * IdleDetector - Detects system-wide user inactivity using IOKit.
 * 
 * Queries the macOS IOHIDSystem to determine how long the system has been idle
 * (no keyboard or mouse input). Used to distinguish between active usage and
 * passive time (e.g., watching videos, reading, or being away from computer).
 * 
 * **How It Works:**
 * - Queries IORegistry for HIDIdleTime property
 * - Returns time in seconds since last keyboard/mouse input
 * - System-wide metric (not per-app)
 * - Lightweight operation suitable for frequent polling
 * 
 * **No Special Permissions Required:**
 * Uses public IOKit APIs available to all macOS apps.
 */
class IdleDetector {
    
    /**
     * Returns the number of seconds since the last user input.
     * 
     * Queries the IOHIDSystem registry for the HIDIdleTime property,
     * which tracks time since last keyboard or mouse activity.
     * 
     * - Returns: Idle time in seconds, or nil if unable to retrieve
     */
    func getSystemIdleTime() -> TimeInterval? {
        var iterator: io_iterator_t = 0
        defer { IOObjectRelease(iterator) }
        
        // Get IOHIDSystem service
        guard IOServiceGetMatchingServices(kIOMainPortDefault, 
                                          IOServiceMatching("IOHIDSystem"), 
                                          &iterator) == KERN_SUCCESS else {
            return nil
        }
        
        let entry: io_registry_entry_t = IOIteratorNext(iterator)
        defer { IOObjectRelease(entry) }
        guard entry != 0 else { return nil }
        
        // Get properties dictionary
        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        defer { unmanagedDict?.release() }
        
        guard IORegistryEntryCreateCFProperties(entry, 
                                               &unmanagedDict, 
                                               kCFAllocatorDefault, 
                                               0) == KERN_SUCCESS else {
            return nil
        }
        
        guard let dict = unmanagedDict?.takeUnretainedValue() else { return nil }
        
        // Extract HIDIdleTime value
        let key: CFString = "HIDIdleTime" as CFString
        guard let value = CFDictionaryGetValue(dict, Unmanaged.passUnretained(key).toOpaque()) else {
            return nil
        }
        
        let number: CFNumber = unsafeBitCast(value, to: CFNumber.self)
        var nanoseconds: Int64 = 0
        
        guard CFNumberGetValue(number, CFNumberType.sInt64Type, &nanoseconds) else {
            return nil
        }
        
        // Convert nanoseconds to seconds
        let seconds = Double(nanoseconds) / Double(NSEC_PER_SEC)
        return seconds
    }
    
    /**
     * Checks if the system is currently idle based on a threshold.
     * 
     * - Parameter threshold: Idle time threshold in seconds
     * - Returns: True if system has been idle longer than threshold
     */
    func isSystemIdle(threshold: TimeInterval) -> Bool {
        guard let idleTime = getSystemIdleTime() else {
            return false // Assume active if we can't determine
        }
        return idleTime >= threshold
    }
}
