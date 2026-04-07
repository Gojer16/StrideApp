import Foundation

// MARK: - Get Habits Tool

struct GetHabitsTool: MCPTool {
    let name = "get_habits"
    let description = "List all habits with their statistics including streaks and completion rates"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "includeArchived": JSONSchemaBuilder.boolean(description: "Include archived habits (default: false)"),
                "frequency": JSONSchemaBuilder.string(description: "Filter by frequency: 'daily', 'weekly', 'monthly'")
            ],
            required: []
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        let db = HabitDatabase.shared
        let includeArchived = paramBool(parameters, "includeArchived") ?? false
        let frequencyFilter = paramString(parameters, "frequency")

        var habits = db.getAllHabits()

        // Filter by archived status
        if !includeArchived {
            habits = habits.filter { !$0.isArchived }
        }

        // Filter by frequency
        if let freq = frequencyFilter,
           let frequency = HabitFrequency(rawValue: freq) {
            habits = habits.filter { $0.frequency == frequency }
        }

        let habitsData = habits.map { habit -> [String: Any] in
            let stats = db.getStatistics(for: habit)
            let streak = db.getStreak(for: habit)

            return [
                "id": habit.id.uuidString,
                "name": habit.name,
                "icon": habit.icon,
                "color": habit.color,
                "type": habit.type.rawValue,
                "frequency": habit.frequency.rawValue,
                "targetValue": habit.targetValue,
                "formattedTarget": habit.formattedTarget,
                "reminderEnabled": habit.reminderEnabled,
                "isArchived": habit.isArchived,
                "createdAt": ISO8601DateFormatter().string(from: habit.createdAt),
                "statistics": [
                    "totalEntries": stats.totalEntries,
                    "completionRate": stats.completionRate,
                    "formattedCompletionRate": stats.formattedCompletionRate,
                    "currentStreak": streak.currentStreak,
                    "longestStreak": streak.longestStreak,
                    "totalValue": stats.totalValue,
                    "formattedTotal": stats.formattedTotal
                ]
            ]
        }

        return .success(dict: [
            "habits": habitsData,
            "totalCount": habitsData.count
        ])
    }
}

// MARK: - Get Habit Entries Tool

struct GetHabitEntriesTool: MCPTool {
    let name = "get_habit_entries"
    let description = "Get entries for a specific habit within a date range"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "habitId": JSONSchemaBuilder.string(description: "UUID of the habit"),
                "startDate": JSONSchemaBuilder.string(description: "Start date in ISO8601 format (optional)"),
                "endDate": JSONSchemaBuilder.string(description: "End date in ISO8601 format (optional)"),
                "limit": JSONSchemaBuilder.integer(description: "Maximum number of entries to return (default: 100)")
            ],
            required: ["habitId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let habitIdStr = paramString(parameters, "habitId"),
              let habitId = UUID(uuidString: habitIdStr) else {
            return .failure("Missing or invalid habitId parameter")
        }

        let db = HabitDatabase.shared

        guard let habit = db.getHabit(byId: habitId) else {
            return .failure("Habit '\(habitIdStr)' not found")
        }

        let startDate = paramString(parameters, "startDate").flatMap { ISO8601DateFormatter().date(from: $0) }
        let endDate = paramString(parameters, "endDate").flatMap { ISO8601DateFormatter().date(from: $0) }
        let limit = paramInt(parameters, "limit") ?? 100

        let entries = db.getEntries(for: habitId, from: startDate, to: endDate)
        let limitedEntries = Array(entries.prefix(limit))

        let entriesData = limitedEntries.map { entry -> [String: Any] in
            return [
                "id": entry.id.uuidString,
                "habitId": entry.habitId.uuidString,
                "date": ISO8601DateFormatter().string(from: entry.date),
                "value": entry.value,
                "notes": entry.notes,
                "formattedValue": entry.formattedValue(for: habit.type),
                "isCompleted": entry.isCompleted,
                "createdAt": ISO8601DateFormatter().string(from: entry.createdAt)
            ]
        }

        return .success(dict: [
            "habit": [
                "id": habit.id.uuidString,
                "name": habit.name,
                "type": habit.type.rawValue
            ],
            "entries": entriesData,
            "count": entriesData.count
        ])
    }
}

// MARK: - Get Habit Streak Tool

struct GetHabitStreakTool: MCPTool {
    let name = "get_habit_streak"
    let description = "Get streak information for a specific habit"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "habitId": JSONSchemaBuilder.string(description: "UUID of the habit")
            ],
            required: ["habitId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let habitIdStr = paramString(parameters, "habitId"),
              let habitId = UUID(uuidString: habitIdStr) else {
            return .failure("Missing or invalid habitId parameter")
        }

        let db = HabitDatabase.shared

        guard let habit = db.getHabit(byId: habitId) else {
            return .failure("Habit '\(habitIdStr)' not found")
        }

        let streak = db.getStreak(for: habit)
        let stats = db.getStatistics(for: habit)

        return .success(dict: [
            "habitId": habit.id.uuidString,
            "habitName": habit.name,
            "type": habit.type.rawValue,
            "frequency": habit.frequency.rawValue,
            "currentStreak": streak.currentStreak,
            "longestStreak": streak.longestStreak,
            "isActive": streak.isActive,
            "lastCompletedDate": streak.lastCompletedDate.map { ISO8601DateFormatter().string(from: $0) } ?? NSNull(),
            "completionRate": stats.completionRate,
            "formattedCompletionRate": stats.formattedCompletionRate,
            "totalEntries": stats.totalEntries
        ])
    }
}

// MARK: - Create Habit Tool

struct CreateHabitTool: MCPTool {
    let name = "create_habit"
    let description = "Create a new habit"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "name": JSONSchemaBuilder.string(description: "Habit name"),
                "icon": JSONSchemaBuilder.string(description: "SF Symbol icon name (e.g., 'star.fill')"),
                "color": JSONSchemaBuilder.string(description: "Hex color code (e.g., '#4A7C59')"),
                "type": JSONSchemaBuilder.string(description: "Habit type: 'checkbox', 'timer', or 'counter'"),
                "frequency": JSONSchemaBuilder.string(description: "Frequency: 'daily', 'weekly', or 'monthly'"),
                "targetValue": JSONSchemaBuilder.number(description: "Target value (count for counter, minutes for timer)"),
                "reminderEnabled": JSONSchemaBuilder.boolean(description: "Enable reminders (default: false)")
            ],
            required: ["name"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let name = paramString(parameters, "name") else {
            return .failure("Missing required parameter: name")
        }

        let icon = paramString(parameters, "icon") ?? "star.fill"
        let color = paramString(parameters, "color") ?? "#4A7C59"
        let typeStr = paramString(parameters, "type") ?? "checkbox"
        let frequencyStr = paramString(parameters, "frequency") ?? "daily"
        let targetValue = paramDouble(parameters, "targetValue") ?? 1.0
        let reminderEnabled = paramBool(parameters, "reminderEnabled") ?? false

        guard let type = HabitType(rawValue: typeStr) else {
            return .failure("Invalid habit type. Must be 'checkbox', 'timer', or 'counter'")
        }

        guard let frequency = HabitFrequency(rawValue: frequencyStr) else {
            return .failure("Invalid frequency. Must be 'daily', 'weekly', or 'monthly'")
        }

        let habit = Habit(
            name: name,
            icon: icon,
            color: color,
            type: type,
            frequency: frequency,
            targetValue: targetValue,
            reminderEnabled: reminderEnabled
        )

        let db = HabitDatabase.shared
        let result = db.createHabit(habit)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "id": habit.id.uuidString,
                "name": name,
                "type": typeStr,
                "frequency": frequencyStr,
                "message": "Habit '\(name)' created successfully"
            ])
        case .failure(let error):
            return .failure("Failed to create habit: \(error.localizedDescription)")
        }
    }
}

// MARK: - Update Habit Tool

struct UpdateHabitTool: MCPTool {
    let name = "update_habit"
    let description = "Update an existing habit's properties"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "habitId": JSONSchemaBuilder.string(description: "UUID of the habit to update"),
                "name": JSONSchemaBuilder.string(description: "New name (optional)"),
                "icon": JSONSchemaBuilder.string(description: "New SF Symbol icon name (optional)"),
                "color": JSONSchemaBuilder.string(description: "New hex color code (optional)"),
                "type": JSONSchemaBuilder.string(description: "New type (optional)"),
                "frequency": JSONSchemaBuilder.string(description: "New frequency (optional)"),
                "targetValue": JSONSchemaBuilder.number(description: "New target value (optional)"),
                "isArchived": JSONSchemaBuilder.boolean(description: "Archive/unarchive habit (optional)")
            ],
            required: ["habitId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let habitIdStr = paramString(parameters, "habitId"),
              let habitId = UUID(uuidString: habitIdStr) else {
            return .failure("Missing or invalid habitId parameter")
        }

        let db = HabitDatabase.shared

        guard var habit = db.getHabit(byId: habitId) else {
            return .failure("Habit '\(habitIdStr)' not found")
        }

        // Update only provided fields
        if let name = paramString(parameters, "name") {
            habit = Habit(
                id: habit.id,
                name: name,
                icon: habit.icon,
                color: habit.color,
                type: habit.type,
                frequency: habit.frequency,
                targetValue: habit.targetValue,
                reminderTime: habit.reminderTime,
                reminderEnabled: habit.reminderEnabled,
                createdAt: habit.createdAt,
                isArchived: habit.isArchived
            )
        }

        if let icon = paramString(parameters, "icon"),
           let name = paramString(parameters, "name") ?? nil {
            habit = Habit(
                id: habit.id,
                name: habit.name,
                icon: icon,
                color: habit.color,
                type: habit.type,
                frequency: habit.frequency,
                targetValue: habit.targetValue,
                reminderTime: habit.reminderTime,
                reminderEnabled: habit.reminderEnabled,
                createdAt: habit.createdAt,
                isArchived: habit.isArchived
            )
        }

        if let color = paramString(parameters, "color") {
            habit = Habit(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: color,
                type: habit.type,
                frequency: habit.frequency,
                targetValue: habit.targetValue,
                reminderTime: habit.reminderTime,
                reminderEnabled: habit.reminderEnabled,
                createdAt: habit.createdAt,
                isArchived: habit.isArchived
            )
        }

        if let typeStr = paramString(parameters, "type"),
           let type = HabitType(rawValue: typeStr) {
            habit = Habit(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: habit.color,
                type: type,
                frequency: habit.frequency,
                targetValue: habit.targetValue,
                reminderTime: habit.reminderTime,
                reminderEnabled: habit.reminderEnabled,
                createdAt: habit.createdAt,
                isArchived: habit.isArchived
            )
        }

        if let frequencyStr = paramString(parameters, "frequency"),
           let frequency = HabitFrequency(rawValue: frequencyStr) {
            habit = Habit(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: habit.color,
                type: habit.type,
                frequency: frequency,
                targetValue: habit.targetValue,
                reminderTime: habit.reminderTime,
                reminderEnabled: habit.reminderEnabled,
                createdAt: habit.createdAt,
                isArchived: habit.isArchived
            )
        }

        if let targetValue = paramDouble(parameters, "targetValue") {
            habit = Habit(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: habit.color,
                type: habit.type,
                frequency: habit.frequency,
                targetValue: targetValue,
                reminderTime: habit.reminderTime,
                reminderEnabled: habit.reminderEnabled,
                createdAt: habit.createdAt,
                isArchived: habit.isArchived
            )
        }

        if let isArchived = paramBool(parameters, "isArchived") {
            habit = Habit(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                color: habit.color,
                type: habit.type,
                frequency: habit.frequency,
                targetValue: habit.targetValue,
                reminderTime: habit.reminderTime,
                reminderEnabled: habit.reminderEnabled,
                createdAt: habit.createdAt,
                isArchived: isArchived
            )
        }

        let result = db.updateHabit(habit)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "id": habit.id.uuidString,
                "name": habit.name,
                "message": "Habit '\(habit.name)' updated successfully"
            ])
        case .failure(let error):
            return .failure("Failed to update habit: \(error.localizedDescription)")
        }
    }
}

// MARK: - Log Habit Entry Tool

struct LogHabitEntryTool: MCPTool {
    let name = "log_habit_entry"
    let description = "Log/record a habit completion entry"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "habitId": JSONSchemaBuilder.string(description: "UUID of the habit"),
                "date": JSONSchemaBuilder.string(description: "Date in ISO8601 format (default: now)"),
                "value": JSONSchemaBuilder.number(description: "Value to log (default: 1 for checkbox/counter, minutes for timer)"),
                "notes": JSONSchemaBuilder.string(description: "Optional notes for this entry")
            ],
            required: ["habitId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let habitIdStr = paramString(parameters, "habitId"),
              let habitId = UUID(uuidString: habitIdStr) else {
            return .failure("Missing or invalid habitId parameter")
        }

        let db = HabitDatabase.shared

        guard let habit = db.getHabit(byId: habitId) else {
            return .failure("Habit '\(habitIdStr)' not found")
        }

        let date = paramString(parameters, "date").flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        let value = paramDouble(parameters, "value") ?? 1.0
        let notes = paramString(parameters, "notes") ?? ""

        let entry = HabitEntry(
            habitId: habitId,
            date: date,
            value: value,
            notes: notes
        )

        let result = db.addEntry(entry)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "entryId": entry.id.uuidString,
                "habitId": habitIdStr,
                "habitName": habit.name,
                "date": ISO8601DateFormatter().string(from: date),
                "value": value,
                "message": "Entry logged for habit '\(habit.name)'"
            ])
        case .failure(let error):
            return .failure("Failed to log habit entry: \(error.localizedDescription)")
        }
    }
}

// MARK: - Delete Habit Tool

struct DeleteHabitTool: MCPTool {
    let name = "delete_habit"
    let description = "Delete a habit and all its entries"

    var inputSchema: [String: Any] {
        return JSONSchemaBuilder.inputSchema(
            properties: [
                "habitId": JSONSchemaBuilder.string(description: "UUID of the habit to delete")
            ],
            required: ["habitId"]
        )
    }

    func execute(parameters: [String: Any]) async -> MCPToolResult {
        guard let habitIdStr = paramString(parameters, "habitId"),
              let habitId = UUID(uuidString: habitIdStr) else {
            return .failure("Missing or invalid habitId parameter")
        }

        let db = HabitDatabase.shared

        guard let habit = db.getHabit(byId: habitId) else {
            return .failure("Habit '\(habitIdStr)' not found")
        }

        let result = db.deleteHabit(id: habitId)

        switch result {
        case .success:
            return .success(dict: [
                "success": true,
                "deletedHabitId": habitIdStr,
                "deletedHabitName": habit.name,
                "message": "Habit '\(habit.name)' deleted successfully"
            ])
        case .failure(let error):
            return .failure("Failed to delete habit: \(error.localizedDescription)")
        }
    }
}