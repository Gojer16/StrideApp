import Foundation

// MARK: - Get Weekly Entries Tool

struct GetWeeklyEntriesTool: MCPTool {
    let name = "get_weekly_entries"
    let description = "Get log entries for a specific week"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "weekStartDate": JSONSchemaBuilder.string(description: "Start date of the week in ISO8601 format (Monday). Defaults to current week."),
                "includeCategoryColors": JSONSchemaBuilder.boolean(description: "Include category colors in response (default: true)")
            ],
            required: []
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = WeeklyLogDatabase.shared
        let calendar = Calendar.current

        let weekStartDate: Date
        if let dateStr = paramString(parameters, "weekStartDate"),
           let parsed = ISO8601DateFormatter().date(from: dateStr) {
            weekStartDate = parsed.startOfWeek
        } else {
            weekStartDate = Date().startOfWeek
        }

        let includeColors = paramBool(parameters, "includeCategoryColors") ?? true
        let entries = db.getEntriesForWeek(startingFrom: weekStartDate)

        let entriesData = entries.map { entry -> [String: Any] in
            var data: [String: Any] = [
                "id": entry.id.uuidString,
                "date": ISO8601DateFormatter().string(from: entry.date),
                "formattedDate": entry.date.formattedDay,
                "category": entry.category,
                "task": entry.task,
                "timeSpent": entry.timeSpent,
                "formattedTime": entry.formattedTime,
                "progressNote": entry.progressNote,
                "winNote": entry.winNote,
                "isWinOfDay": entry.isWinOfDay,
                "createdAt": ISO8601DateFormatter().string(from: entry.createdAt)
            ]

            if includeColors {
                data["categoryColor"] = db.getCategoryColor(for: entry.category) ?? "#6B7B7B"
            }

            return data
        }

        // Calculate daily totals
        var dailyTotals: [String: [String: Any]] = [:]
        for entry in entries {
            let dayKey = ISO8601DateFormatter().string(from: entry.date)
            if dailyTotals[dayKey] == nil {
                dailyTotals[dayKey] = ["date": dayKey, "totalTime": 0.0]
            }
            dailyTotals[dayKey]?["totalTime"] = (dailyTotals[dayKey]?["totalTime"] as? Double ?? 0) + entry.timeSpent
        }

        return .success(dict: [
            "weekStartDate": ISO8601DateFormatter().string(from: weekStartDate),
            "weekEndDate": ISO8601DateFormatter().string(from: weekStartDate.adding(days: 6)),
            "formattedWeekRange": WeekInfo(startDate: weekStartDate, endDate: weekStartDate.adding(days: 6), weekNumber: 0, year: 0).formattedRange,
            "entries": entriesData,
            "entryCount": entriesData.count,
            "dailyTotals": Array(dailyTotals.values)
        ])
    }
}

// MARK: - Get Weekly Summary Tool

struct GetWeeklySummaryTool: MCPTool {
    let name = "get_weekly_summary"
    let description = "Get time totals by category for a week"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "weekStartDate": JSONSchemaBuilder.string(description: "Start date of the week in ISO8601 format (Monday). Defaults to current week.")
            ],
            required: []
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = WeeklyLogDatabase.shared

        let weekStartDate: Date
        if let dateStr = paramString(parameters, "weekStartDate"),
           let parsed = ISO8601DateFormatter().date(from: dateStr) {
            weekStartDate = parsed.startOfWeek
        } else {
            weekStartDate = Date().startOfWeek
        }

        let categoryTotals = db.getCategoryTotals(for: weekStartDate)
        let allEntries = db.getEntriesForWeek(startingFrom: weekStartDate)

        // Calculate total time
        let totalTime = categoryTotals.reduce(0.0) { $0 + $1.total }

        // Get categories with colors
        let categories = db.getAllCategories()
        var categoryData: [[String: Any]] = []

        for (category, total) in categoryTotals {
            let color = db.getCategoryColor(for: category) ?? "#6B7B7B"
            let percentage = totalTime > 0 ? (total / totalTime) * 100 : 0

            categoryData.append([
                "category": category,
                "timeSpent": total,
                "formattedTime": formatHours(total),
                "color": color,
                "percentage": round(percentage * 10) / 10
            ])
        }

        // Sort by time spent
        categoryData.sort { ($0["timeSpent"] as? Double ?? 0) > ($1["timeSpent"] as? Double ?? 0) }

        // Calculate daily breakdown
        var dailyData: [String: [String: Any]] = [:]
        let calendar = Calendar.current
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: weekStartDate) {
                let dayKey = ISO8601DateFormatter().string(from: day)
                dailyData[dayKey] = [
                    "date": dayKey,
                    "dayName": day.shortDayName,
                    "totalTime": 0.0
                ]
            }
        }

        for entry in allEntries {
            let dayKey = ISO8601DateFormatter().string(from: entry.date)
            if dailyData[dayKey] != nil {
                dailyData[dayKey]?["totalTime"] = (dailyData[dayKey]?["totalTime"] as? Double ?? 0) + entry.timeSpent
            }
        }

        return .success(dict: [
            "weekStartDate": ISO8601DateFormatter().string(from: weekStartDate),
            "weekEndDate": ISO8601DateFormatter().string(from: weekStartDate.adding(days: 6)),
            "totalTime": totalTime,
            "formattedTotalTime": formatHours(totalTime),
            "totalEntries": allEntries.count,
            "categories": categoryData,
            "dailyBreakdown": Array(dailyData.values).sorted { ($0["date"] as? String ?? "") < ($1["date"] as? String ?? "") }
        ])
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if h > 0 {
            return "\(h)h \(m)m"
        } else {
            return "\(m)m"
        }
    }
}

// MARK: - Create Log Entry Tool

struct CreateLogEntryTool: MCPTool {
    let name = "create_log_entry"
    let description = "Create a new focus session/log entry"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "date": JSONSchemaBuilder.string(description: "Date in ISO8601 format (default: now)"),
                "category": JSONSchemaBuilder.string(description: "Category name (e.g., 'Work', 'Development')"),
                "task": JSONSchemaBuilder.string(description: "Task description"),
                "timeSpent": JSONSchemaBuilder.number(description: "Time spent in hours (max 2.0)"),
                "progressNote": JSONSchemaBuilder.string(description: "Optional progress notes"),
                "winNote": JSONSchemaBuilder.string(description: "Optional win/achievement notes"),
                "isWinOfDay": JSONSchemaBuilder.boolean(description: "Mark as win of the day (default: false)")
            ],
            required: ["category", "task", "timeSpent"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let category = paramString(parameters, "category") else {
            return .failure("Missing required parameter: category")
        }

        guard let task = paramString(parameters, "task") else {
            return .failure("Missing required parameter: task")
        }

        guard let timeSpent = paramDouble(parameters, "timeSpent") else {
            return .failure("Missing required parameter: timeSpent")
        }

        let date = paramString(parameters, "date").flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        let progressNote = paramString(parameters, "progressNote") ?? ""
        let winNote = paramString(parameters, "winNote") ?? ""
        let isWinOfDay = paramBool(parameters, "isWinOfDay") ?? false

        // Validate time spent (max 2 hours)
        guard timeSpent > 0 && timeSpent <= 2.0 else {
            return .failure("timeSpent must be between 0 and 2 hours")
        }

        let entry = WeeklyLogEntry(
            date: date,
            category: category,
            task: task,
            timeSpent: timeSpent,
            progressNote: progressNote,
            winNote: winNote,
            isWinOfDay: isWinOfDay
        )

        let db = WeeklyLogDatabase.shared
        let result = db.createEntry(entry)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "entryId": entry.id.uuidString,
                "date": ISO8601DateFormatter().string(from: date),
                "category": category,
                "task": task,
                "timeSpent": timeSpent,
                "formattedTime": entry.formattedTime,
                "message": "Log entry created successfully"
            ])
        case .failure(let error):
            return .failure("Failed to create log entry: \(error.localizedDescription)")
        }
    }
}

// MARK: - Update Log Entry Tool

struct UpdateLogEntryTool: MCPTool {
    let name = "update_log_entry"
    let description = "Update an existing log entry"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "entryId": JSONSchemaBuilder.string(description: "UUID of the entry to update"),
                "date": JSONSchemaBuilder.string(description: "New date in ISO8601 format (optional)"),
                "category": JSONSchemaBuilder.string(description: "New category name (optional)"),
                "task": JSONSchemaBuilder.string(description: "New task description (optional)"),
                "timeSpent": JSONSchemaBuilder.number(description: "New time spent in hours (optional)"),
                "progressNote": JSONSchemaBuilder.string(description: "New progress notes (optional)"),
                "winNote": JSONSchemaBuilder.string(description: "New win notes (optional)"),
                "isWinOfDay": JSONSchemaBuilder.boolean(description: "Mark as win of the day (optional)")
            ],
            required: ["entryId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let entryIdStr = paramString(parameters, "entryId"),
              let entryId = UUID(uuidString: entryIdStr) else {
            return .failure("Missing or invalid entryId parameter")
        }

        let db = WeeklyLogDatabase.shared

        // Get existing entry
        let allEntries = db.getAllEntries()
        guard let existingEntry = allEntries.first(where: { $0.id == entryId }) else {
            return .failure("Log entry '\(entryIdStr)' not found")
        }

        // Build updated entry
        let date = paramString(parameters, "date").flatMap { ISO8601DateFormatter().date(from: $0) } ?? existingEntry.date
        let category = paramString(parameters, "category") ?? existingEntry.category
        let task = paramString(parameters, "task") ?? existingEntry.task
        var timeSpent = paramDouble(parameters, "timeSpent") ?? existingEntry.timeSpent
        let progressNote = paramString(parameters, "progressNote") ?? existingEntry.progressNote
        let winNote = paramString(parameters, "winNote") ?? existingEntry.winNote
        let isWinOfDay = paramBool(parameters, "isWinOfDay") ?? existingEntry.isWinOfDay

        // Validate time spent
        if let newTime = paramDouble(parameters, "timeSpent"), (newTime <= 0 || newTime > 2.0) {
            return .failure("timeSpent must be between 0 and 2 hours")
        }

        let updatedEntry = WeeklyLogEntry(
            id: entryId,
            date: date,
            category: category,
            task: task,
            timeSpent: timeSpent,
            progressNote: progressNote,
            winNote: winNote,
            isWinOfDay: isWinOfDay,
            createdAt: existingEntry.createdAt
        )

        let result = db.updateEntry(updatedEntry)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "entryId": entryIdStr,
                "category": category,
                "task": task,
                "timeSpent": timeSpent,
                "message": "Log entry updated successfully"
            ])
        case .failure(let error):
            return .failure("Failed to update log entry: \(error.localizedDescription)")
        }
    }
}

// MARK: - Delete Log Entry Tool

struct DeleteLogEntryTool: MCPTool {
    let name = "delete_log_entry"
    let description = "Delete a log entry"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "entryId": JSONSchemaBuilder.string(description: "UUID of the entry to delete")
            ],
            required: ["entryId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let entryIdStr = paramString(parameters, "entryId"),
              let entryId = UUID(uuidString: entryIdStr) else {
            return .failure("Missing or invalid entryId parameter")
        }

        let db = WeeklyLogDatabase.shared

        // Verify entry exists
        let allEntries = db.getAllEntries()
        guard let existingEntry = allEntries.first(where: { $0.id == entryId }) else {
            return .failure("Log entry '\(entryIdStr)' not found")
        }

        let result = db.deleteEntry(id: entryId)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "deletedEntryId": entryIdStr,
                "deletedTask": existingEntry.task,
                "message": "Log entry deleted successfully"
            ])
        case .failure(let error):
            return .failure("Failed to delete log entry: \(error.localizedDescription)")
        }
    }
}

// MARK: - Get Categories Tool (for Weekly Log)

struct GetWeeklyCategoriesTool: MCPTool {
    let name = "get_weekly_categories"
    let description = "List all categories used in weekly log entries with their colors"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(properties: [:], required: [])
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = WeeklyLogDatabase.shared
        let categories = db.getAllCategories()

        let categoriesData = categories.map { category -> [String: Any] in
            let color = db.getCategoryColor(for: category) ?? "#6B7B7B"
            return [
                "name": category,
                "color": color
            ]
        }

        return .success(dict: [
            "categories": categoriesData,
            "count": categoriesData.count
        ])
    }
}

// MARK: - Set Category Color Tool

struct SetCategoryColorTool: MCPTool {
    let name = "set_category_color"
    let description = "Set the color for a weekly log category"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "category": JSONSchemaBuilder.string(description: "Category name"),
                "color": JSONSchemaBuilder.string(description: "Hex color code (e.g., '#C75B39')")
            ],
            required: ["category", "color"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let category = paramString(parameters, "category") else {
            return .failure("Missing required parameter: category")
        }

        guard let color = paramString(parameters, "color") else {
            return .failure("Missing required parameter: color")
        }

        // Validate color format
        guard color.hasPrefix("#") && color.count == 7 else {
            return .failure("Invalid color format. Must be hex format like '#C75B39'")
        }

        let db = WeeklyLogDatabase.shared
        let result = db.setCategoryColor(for: category, color: color)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "category": category,
                "color": color,
                "message": "Color set for category '\(category)'"
            ])
        case .failure(let error):
            return .failure("Failed to set category color: \(error.localizedDescription)")
        }
    }
}