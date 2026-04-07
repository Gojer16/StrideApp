import Foundation

// MARK: - MCP Tool Protocol

/// Protocol for MCP tools that can be invoked by AI agents
protocol MCPTool {
    /// Unique name for the tool
    var name: String { get }

    /// Human-readable description
    var description: String { get }

    /// JSON Schema for input parameters
    var inputSchema: [String: Any] { get }

    /// Execute the tool with given parameters
    func execute(parameters: [String: Any]) async -> MCPToolResult

    /// Convert input schema to JSONValue for serialization
    func schemaAsJSON() -> JSONValue
}

extension MCPTool {
    func schemaAsJSON() -> JSONValue {
        return .from(inputSchema)
    }

    /// Helper to extract string parameter
    func paramString(_ params: [String: Any], _ key: String) -> String? {
        return params[key] as? String
    }

    /// Helper to extract int parameter
    func paramInt(_ params: [String: Any], _ key: String) -> Int? {
        return params[key] as? Int
    }

    /// Helper to extract double parameter
    func paramDouble(_ params: [String: Any], _ key: String) -> Double? {
        return params[key] as? Double
    }

    /// Helper to extract bool parameter
    func paramBool(_ params: [String: Any], _ key: String) -> Bool? {
        return params[key] as? Bool
    }

    /// Helper to extract array parameter
    func paramArray(_ params: [String: Any], _ key: String) -> [Any]? {
        return params[key] as? [Any]
    }

    /// Helper to extract object parameter
    func paramObject(_ params: [String: Any], _ key: String) -> [String: Any]? {
        return params[key] as? [String: Any]
    }
}

// MARK: - Tool Result Helpers

extension MCPToolResult {
    /// Create a success result with JSON data
    static func success<T: Encodable>(_ value: T) -> MCPToolResult {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]

        do {
            let data = try encoder.encode(value)
            if let jsonString = String(data: data, encoding: .utf8) {
                return MCPToolResult(text: jsonString)
            }
            return MCPToolResult(error: "Failed to encode result")
        } catch {
            return MCPToolResult(error: "Encoding error: \(error.localizedDescription)")
        }
    }

    /// Create a success result with a dictionary
    static func success(dict: [String: Any]) -> MCPToolResult {
        let value = JSONValue.from(dict)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]

        do {
            let data = try encoder.encode(value)
            if let jsonString = String(data: data, encoding: .utf8) {
                return MCPToolResult(text: jsonString)
            }
            return MCPToolResult(error: "Failed to encode result")
        } catch {
            return MCPToolResult(error: "Encoding error: \(error.localizedDescription)")
        }
    }

    /// Create an error result
    static func failure(_ message: String) -> MCPToolResult {
        return MCPToolResult(error: message)
    }
}

// MARK: - Common Schemas

struct JSONSchemaBuilder {
    /// Build a string schema
    static func string(description: String? = nil, required: Bool = true) -> [String: Any] {
        var schema: [String: Any] = ["type": "string"]
        if let desc = description { schema["description"] = desc }
        return schema
    }

    /// Build an integer schema
    static func integer(description: String? = nil) -> [String: Any] {
        var schema: [String: Any] = ["type": "integer"]
        if let desc = description { schema["description"] = desc }
        return schema
    }

    /// Build a number schema
    static func number(description: String? = nil) -> [String: Any] {
        var schema: [String: Any] = ["type": "number"]
        if let desc = description { schema["description"] = desc }
        return schema
    }

    /// Build a boolean schema
    static func boolean(description: String? = nil) -> [String: Any] {
        var schema: [String: Any] = ["type": "boolean"]
        if let desc = description { schema["description"] = desc }
        return schema
    }

    /// Build an object schema
    static func object(
        properties: [String: [String: Any]],
        required: [String]? = nil,
        description: String? = nil
    ) -> [String: Any] {
        var schema: [String: Any] = [
            "type": "object",
            "properties": properties
        ]
        if let req = required, !req.isEmpty {
            schema["required"] = req
        }
        if let desc = description { schema["description"] = desc }
        return schema
    }

    /// Build an array schema
    static func array(
        items: [String: Any],
        description: String? = nil
    ) -> [String: Any] {
        var schema: [String: Any] = [
            "type": "array",
            "items": items
        ]
        if let desc = description { schema["description"] = desc }
        return schema
    }

    /// Build a schema with enum values
    static func `enum`(
        values: [Any],
        description: String? = nil
    ) -> [String: Any] {
        var schema: [String: Any] = ["enum": values]
        if let desc = description { schema["description"] = desc }
        return schema
    }

    /// Build the full input schema for a tool
    static func inputSchema(
        properties: [String: [String: Any]],
        required: [String] = []
    ) -> [String: Any] {
        return [
            "type": "object",
            "properties": properties,
            "required": required
        ]
    }
}