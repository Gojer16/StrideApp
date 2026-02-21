import Foundation

/**
 * DomainParser - Extracts domain names from browser window titles.
 * 
 * **Purpose:**
 * Browser window titles often contain page titles and URLs. This parser extracts
 * the domain name to provide granular insights into web usage (e.g., "github.com"
 * instead of just "Google Chrome").
 * 
 * **Supported Formats:**
 * - "Page Title - Google Chrome" → extract from page title
 * - "Page Title — Safari" → extract from page title
 * - "github.com/user/repo" → "github.com"
 * - "https://stackoverflow.com/questions/..." → "stackoverflow.com"
 * - "YouTube" → "youtube.com" (common site names)
 */
struct DomainParser {
    
    /// Common browser suffixes to strip from titles
    private static let browserSuffixes = [
        " - Google Chrome",
        " — Safari",
        " - Safari",
        " - Mozilla Firefox",
        " - Firefox",
        " - Microsoft Edge",
        " - Brave",
        " - Arc",
        " - Vivaldi"
    ]
    
    /// Common site names mapped to domains
    private static let commonSites: [String: String] = [
        "youtube": "youtube.com",
        "github": "github.com",
        "stackoverflow": "stackoverflow.com",
        "stack overflow": "stackoverflow.com",
        "reddit": "reddit.com",
        "twitter": "twitter.com",
        "facebook": "facebook.com",
        "linkedin": "linkedin.com",
        "gmail": "gmail.com",
        "google docs": "docs.google.com",
        "google drive": "drive.google.com",
        "google sheets": "sheets.google.com",
        "notion": "notion.so",
        "figma": "figma.com",
        "slack": "slack.com",
        "discord": "discord.com",
        "zoom": "zoom.us",
        "netflix": "netflix.com",
        "spotify": "spotify.com",
        "amazon": "amazon.com"
    ]
    
    /// Special titles that should be ignored (not real domains)
    private static let ignoredTitles = [
        "new tab",
        "untitled",
        "settings",
        "preferences",
        "extensions",
        "downloads",
        "history",
        "bookmarks",
        "about:blank",
        "chrome://",
        "safari://",
        "about:"
    ]
    
    /**
     * Extracts domain from a browser window title.
     * 
     * - Parameter title: The window title from a browser
     * - Returns: Domain name (e.g., "github.com") or nil if no domain found
     */
    static func extractDomain(from title: String) -> String? {
        guard !title.isEmpty else { return nil }
        
        let lowercased = title.lowercased()
        
        // Check if title should be ignored
        for ignored in ignoredTitles {
            if lowercased.contains(ignored) {
                return nil
            }
        }
        
        // Strip browser suffix
        var cleanTitle = title
        for suffix in browserSuffixes {
            if let range = cleanTitle.range(of: suffix, options: .caseInsensitive) {
                cleanTitle = String(cleanTitle[..<range.lowerBound])
                break
            }
        }
        
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespaces)
        
        // Try to extract URL from title
        if let domain = extractDomainFromURL(cleanTitle) {
            return domain
        }
        
        // Check for common site names in title
        for (siteName, domain) in commonSites {
            if lowercased.contains(siteName) {
                return domain
            }
        }
        
        // Try to find domain-like patterns (e.g., "word.com")
        if let domain = extractDomainPattern(from: cleanTitle) {
            return domain
        }
        
        return nil
    }
    
    /**
     * Extracts domain from a URL string.
     */
    private static func extractDomainFromURL(_ string: String) -> String? {
        // Try to parse as URL
        var urlString = string
        
        // Add scheme if missing
        if !urlString.contains("://") {
            urlString = "https://" + urlString
        }
        
        guard let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        
        // Remove www. prefix
        var domain = host
        if domain.hasPrefix("www.") {
            domain = String(domain.dropFirst(4))
        }
        
        return domain.isEmpty ? nil : domain
    }
    
    /**
     * Extracts domain-like patterns from text (e.g., "github.com" from "GitHub - github.com").
     */
    private static func extractDomainPattern(from text: String) -> String? {
        // Regex pattern for domain-like strings
        let pattern = #"([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else {
            return nil
        }
        
        guard let matchRange = Range(match.range, in: text) else {
            return nil
        }
        
        var domain = String(text[matchRange])
        
        // Remove www. prefix
        if domain.hasPrefix("www.") {
            domain = String(domain.dropFirst(4))
        }
        
        return domain
    }
}
