import Foundation

// MARK: - Get Today Stats Tool

struct GetTodayStatsTool: MCPTool {
    let name = "get_today_stats"
    let description = "Get today's app usage summary including total active/passive time, app count, and category breakdown"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(properties: [:], required: [])
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = UsageDatabase.shared
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)

        // Get all apps with today's usage
        let apps = db.getAllApplications()
        var totalActiveTime: TimeInterval = 0
        var totalPassiveTime: TimeInterval = 0
        var totalTrackedApps = 0

        var appStats: [[String: Any]] = []
        var categoryTimes: [String: TimeInterval] = [:]

        for app in apps {
            let windows = db.getWindows(for: app.id.uuidString)
            var appTodayTime: TimeInterval = 0
            var appTodayPassive: TimeInterval = 0

            for window in windows {
                // Get sessions for today
                let sessions = db.getSessionsForWindow(window.id.uuidString, from: startOfDay)
                for session in sessions {
                    appTodayTime += session.duration
                    appTodayPassive += session.passiveDuration
                }
            }

            if appTodayTime > 0 {
                totalTrackedApps += 1
                totalActiveTime += appTodayTime - appTodayPassive
                totalPassiveTime += appTodayPassive

                let category = app.getCategory()
                categoryTimes[category.name, default: 0] += appTodayTime

                appStats.append([
                    "name": app.name,
                    "activeTime": appTodayTime - appTodayPassive,
                    "passiveTime": appTodayPassive,
                    "totalTime": appTodayTime,
                    "category": category.name,
                    "visitCount": app.visitCount
                ])
            }
        }

        // Sort by time and limit to top apps
        appStats.sort { ($0["totalTime"] as? TimeInterval ?? 0) > ($1["totalTime"] as? TimeInterval ?? 0) }
        let topApps = Array(appStats.prefix(20))

        // Format category breakdown
        let categoryBreakdown = categoryTimes.map { (name, time) -> [String: Any] in
            return [
                "category": name,
                "time": time,
                "formattedTime": formatDuration(time)
            ]
        }.sorted { ($0["time"] as? TimeInterval ?? 0) > ($1["time"] as? TimeInterval ?? 0) }

        let result: [String: Any] = [
            "date": ISO8601DateFormatter().string(from: today),
            "totalActiveTime": totalActiveTime,
            "totalPassiveTime": totalPassiveTime,
            "totalTime": totalActiveTime + totalPassiveTime,
            "formattedActiveTime": formatDuration(totalActiveTime),
            "formattedPassiveTime": formatDuration(totalPassiveTime),
            "formattedTotalTime": formatDuration(totalActiveTime + totalPassiveTime),
            "trackedAppsCount": totalTrackedApps,
            "topApps": topApps,
            "categoryBreakdown": categoryBreakdown
        ]

        return .success(dict: result)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Get App Usage Tool

struct GetAppUsageTool: MCPTool {
    let name = "get_app_usage"
    let description = "Get usage statistics for all apps or a specific app by name"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "appName": JSONSchemaBuilder.string(description: "Optional app name to filter. If not provided, returns all apps."),
                "limit": JSONSchemaBuilder.integer(description: "Maximum number of apps to return (default: 50)"),
                "includeWindows": JSONSchemaBuilder.boolean(description: "Include window details (default: false)")
            ],
            required: []
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = UsageDatabase.shared
        let appName = paramString(parameters, "appName")
        let limit = paramInt(parameters, "limit") ?? 50
        let includeWindows = paramBool(parameters, "includeWindows") ?? false

        if let name = appName {
            // Get specific app
            guard let app = db.getApplication(name: name) else {
                return .failure("App '\(name)' not found")
            }

            let windows = includeWindows ? db.getWindows(for: app.id.uuidString) : []
            let windowData = windows.map { window -> [String: Any] in
                return [
                    "title": window.title,
                    "totalTime": window.totalTimeSpent,
                    "formattedTime": formatDuration(window.totalTimeSpent),
                    "visitCount": window.visitCount,
                    "firstSeen": ISO8601DateFormatter().string(from: window.firstSeen),
                    "lastSeen": ISO8601DateFormatter().string(from: window.lastSeen)
                ]
            }

            let result: [String: Any] = [
                "id": app.id.uuidString,
                "name": app.name,
                "category": app.getCategory().name,
                "categoryId": app.categoryId,
                "totalTime": app.totalTimeSpent,
                "formattedTime": formatDuration(app.totalTimeSpent),
                "visitCount": app.visitCount,
                "firstSeen": ISO8601DateFormatter().string(from: app.firstSeen),
                "lastSeen": ISO8601DateFormatter().string(from: app.lastSeen),
                "windows": windowData
            ]

            return .success(dict: result)
        } else {
            // Get all apps
            let apps = db.getAllApplications()
            let limitedApps = Array(apps.prefix(limit))

            let appData = limitedApps.map { app -> [String: Any] in
                var result: [String: Any] = [
                    "id": app.id.uuidString,
                    "name": app.name,
                    "category": app.getCategory().name,
                    "categoryId": app.categoryId,
                    "totalTime": app.totalTimeSpent,
                    "formattedTime": formatDuration(app.totalTimeSpent),
                    "visitCount": app.visitCount,
                    "firstSeen": ISO8601DateFormatter().string(from: app.firstSeen),
                    "lastSeen": ISO8601DateFormatter().string(from: app.lastSeen)
                ]

                if includeWindows {
                    let windows = db.getWindows(for: app.id.uuidString)
                    result["windowCount"] = windows.count
                }

                return result
            }

            return .success(dict: [
                "apps": appData,
                "totalCount": apps.count,
                "returnedCount": appData.count
            ])
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Get Browser Domains Tool

struct GetBrowserDomainsTool: MCPTool {
    let name = "get_browser_domains"
    let description = "Get domain-level usage statistics from browser windows"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "limit": JSONSchemaBuilder.integer(description: "Maximum number of domains to return (default: 20)")
            ],
            required: []
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = UsageDatabase.shared
        let limit = paramInt(parameters, "limit") ?? 20

        let apps = db.getAllApplications()
        var domainStats: [String: (activeTime: TimeInterval, passiveTime: TimeInterval, browser: String)] = [:]

        let browserNames = ["chrome", "safari", "firefox", "edge", "brave", "arc", "vivaldi", "opera"]

        for app in apps {
            let lowerName = app.name.lowercased()
            guard browserNames.contains(where: { lowerName.contains($0) }) else { continue }

            let windows = db.getWindows(for: app.id.uuidString)
            for window in windows {
                // Extract domain from window title
                if let domain = extractDomain(from: window.title) {
                    var stats = domainStats[domain] ?? (0, 0, app.name)
                    stats.activeTime += window.totalTimeSpent
                    // Note: passive time would need session-level data
                    domainStats[domain] = stats
                }
            }
        }

        // Sort by total time and limit
        let sortedDomains = domainStats
            .map { (domain, stats) -> [String: Any] in
                return [
                    "domain": domain,
                    "activeTime": stats.activeTime,
                    "passiveTime": stats.passiveTime,
                    "totalTime": stats.activeTime + stats.passiveTime,
                    "formattedTime": formatDuration(stats.activeTime + stats.passiveTime),
                    "browser": stats.browser
                ]
            }
            .sorted { ($0["totalTime"] as? TimeInterval ?? 0) > ($1["totalTime"] as? TimeInterval ?? 0) }
            .prefix(limit)

        return .success(dict: [
            "domains": Array(sortedDomains),
            "totalCount": domainStats.count
        ])
    }

    private func extractDomain(from title: String) -> String? {
        // Common patterns for browser titles: "Title - Domain" or "Domain - Title"
        let patterns = [
            #"[—\-]\s*([a-zA-Z0-9][-a-zA-Z0-9]*\.)+[a-zA-Z]{2,}"#,  // - domain.com
            #"([a-zA-Z0-9][-a-zA-Z0-9]*\.)+[a-zA-Z]{2,}"#  // domain.com
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
               let range = Range(match.range(at: 1), in: title) {
                return String(title[range]).lowercased()
            }
        }

        return nil
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Get Sessions Tool

struct GetSessionsTool: MCPTool {
    let name = "get_sessions"
    let description = "Get usage sessions for a date range"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "startDate": JSONSchemaBuilder.string(description: "Start date in ISO8601 format (default: start of today)"),
                "endDate": JSONSchemaBuilder.string(description: "End date in ISO8601 format (default: now)"),
                "limit": JSONSchemaBuilder.integer(description: "Maximum number of sessions to return (default: 100)")
            ],
            required: []
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = UsageDatabase.shared
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        let endDate: Date

        if let startStr = paramString(parameters, "startDate"),
           let parsed = ISO8601DateFormatter().date(from: startStr) {
            startDate = calendar.startOfDay(for: parsed)
        } else {
            startDate = calendar.startOfDay(for: now)
        }

        if let endStr = paramString(parameters, "endDate"),
           let parsed = ISO8601DateFormatter().date(from: endStr) {
            endDate = parsed
        } else {
            endDate = now
        }

        let limit = paramInt(parameters, "limit") ?? 100

        // Get all sessions in range
        let sessions = db.getSessionsInRange(start: startDate, end: endDate, limit: limit)

        let sessionData = sessions.map { session -> [String: Any] in
            return [
                "id": session.id.uuidString,
                "appId": session.appId,
                "appName": session.appName,
                "windowTitle": session.windowTitle,
                "startTime": ISO8601DateFormatter().string(from: session.startTime),
                "endTime": session.endTime.map { ISO8601DateFormatter().string(from: $0) } ?? NSNull(),
                "duration": session.duration,
                "passiveDuration": session.passiveDuration,
                "formattedDuration": formatDuration(session.duration)
            ]
        }

        return .success(dict: [
            "sessions": sessionData,
            "count": sessionData.count,
            "startDate": ISO8601DateFormatter().string(from: startDate),
            "endDate": ISO8601DateFormatter().string(from: endDate)
        ])
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Get Categories Tool

struct GetCategoriesTool: MCPTool {
    let name = "get_categories"
    let description = "List all app categories with their app counts and total usage time"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(properties: [:], required: [])
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = UsageDatabase.shared
        let categories = db.getAllCategories()
        let categoryStats = db.getCategoryStats()

        let data = categoryStats.map { (category, time, count) -> [String: Any] in
            return [
                "id": category.id.uuidString,
                "name": category.name,
                "icon": category.icon,
                "color": category.color,
                "isDefault": category.isDefault,
                "totalTime": time,
                "formattedTime": formatDuration(time),
                "appCount": count
            ]
        }

        return .success(dict: [
            "categories": data,
            "totalCount": categories.count
        ])
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Assign App Category Tool

struct AssignAppCategoryTool: MCPTool {
    let name = "assign_app_category"
    let description = "Assign an app to a category"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "appName": JSONSchemaBuilder.string(description: "Name of the app to assign"),
                "categoryId": JSONSchemaBuilder.string(description: "UUID of the category to assign to")
            ],
            required: ["appName", "categoryId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let appName = paramString(parameters, "appName") else {
            return .failure("Missing required parameter: appName")
        }

        guard let categoryId = paramString(parameters, "categoryId") else {
            return .failure("Missing required parameter: categoryId")
        }

        let db = UsageDatabase.shared

        guard let app = db.getApplication(name: appName) else {
            return .failure("App '\(appName)' not found")
        }

        guard db.getCategory(byId: categoryId) != nil else {
            return .failure("Category '\(categoryId)' not found")
        }

        db.updateAppCategory(appId: app.id.uuidString, categoryId: categoryId)

        return .success(dict: [
            "success": true,
            "appName": appName,
            "categoryId": categoryId,
            "message": "App '\(appName)' assigned to category"
        ])
    }
}

// MARK: - Create Category Tool

struct CreateCategoryTool: MCPTool {
    let name = "create_category"
    let description = "Create a new app category"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "name": JSONSchemaBuilder.string(description: "Category name"),
                "icon": JSONSchemaBuilder.string(description: "SF Symbol icon name (e.g., 'folder.fill')"),
                "color": JSONSchemaBuilder.string(description: "Hex color code (e.g., '#FF6B6B')")
            ],
            required: ["name"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let name = paramString(parameters, "name") else {
            return .failure("Missing required parameter: name")
        }

        let icon = paramString(parameters, "icon") ?? "folder.fill"
        let color = paramString(parameters, "color") ?? "#7F8C8D"

        let db = UsageDatabase.shared

        // Check if category with same name exists
        let existing = db.getAllCategories().first { $0.name.lowercased() == name.lowercased() }
        if existing != nil {
            return .failure("Category '\(name)' already exists")
        }

        let category = Category(name: name, icon: icon, color: color)
        db.createCategory(category)

        return .success(dict: [
            "success": true,
            "id": category.id.uuidString,
            "name": name,
            "icon": icon,
            "color": color,
            "message": "Category '\(name)' created"
        ])
    }
}

// MARK: - Helper Extension for UsageDatabase

extension UsageDatabase {
    /// Get sessions in a date range
    func getSessionsInRange(start: Date, end: Date, limit: Int) -> [SessionData] {
        return dbQueue.sync {
            guard db != nil else { return [] }

            var sessions: [SessionData] = []
            let sql = """
                SELECT s.id, s.window_id, s.start_time, s.end_time, s.duration, s.passive_duration,
                       w.app_id, w.title, a.name
                FROM sessions s
                JOIN windows w ON s.window_id = w.id
                JOIN applications a ON w.app_id = a.id
                WHERE s.start_time >= ? AND s.start_time <= ?
                ORDER BY s.start_time DESC
                LIMIT ?;
            """

            var statement: OpaquePointer?

            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return sessions
            }

            sqlite3_bind_double(statement, 1, start.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, end.timeIntervalSince1970)
            sqlite3_bind_int(statement, 3, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))) ?? UUID()
                let startTime = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
                let endTime: Date? = sqlite3_column_type(statement, 3) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
                let duration = sqlite3_column_double(statement, 4)
                let passiveDuration = sqlite3_column_double(statement, 5)
                let appId = String(cString: sqlite3_column_text(statement, 6))
                let windowTitle = String(cString: sqlite3_column_text(statement, 7))
                let appName = String(cString: sqlite3_column_text(statement, 8))

                sessions.append(SessionData(
                    id: id,
                    appId: appId,
                    appName: appName,
                    windowTitle: windowTitle,
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,
                    passiveDuration: passiveDuration
                ))
            }

            sqlite3_finalize(statement)
            return sessions
        }
    }
}

struct SessionData {
    let id: UUID
    let appId: String
    let appName: String
    let windowTitle: String
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let passiveDuration: TimeInterval
}