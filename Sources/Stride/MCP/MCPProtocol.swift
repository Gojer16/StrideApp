import Foundation

// MARK: - JSON-RPC 2.0 Types

/// JSON-RPC 2.0 Request
struct JSONRPCRequest: Codable {
    let jsonrpc: String = "2.0"
    let id: Int?
    let method: String
    let params: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        id = try? container.decode(Int.self, forKey: .id)
        method = try container.decode(String.self, forKey: .method)
        params = try? container.decode([String: JSONValue].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(params, forKey: .params)
    }
}

/// JSON-RPC 2.0 Response
struct JSONRPCResponse: Codable {
    let jsonrpc: String = "2.0"
    let id: Int?
    let result: JSONValue?
    let error: JSONRPCError?

    init(id: Int?, result: JSONValue? = nil, error: JSONRPCError? = nil) {
        self.id = id
        self.result = result
        self.error = error
    }
}

/// JSON-RPC Error
struct JSONRPCError: Codable {
    let code: Int
    let message: String
    let data: JSONValue?

    init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    // Standard JSON-RPC error codes
    static let parseError = JSONRPCError(code: -32700, message: "Parse error")
    static let invalidRequest = JSONRPCError(code: -32600, message: "Invalid Request")
    static let methodNotFound = JSONRPCError(code: -32601, message: "Method not found")
    static let invalidParams = JSONRPCError(code: -32602, message: "Invalid params")
    static let internalError = JSONRPCError(code: -32603, message: "Internal error")
}

// MARK: - JSON Value Type

/// A flexible JSON value type that can hold any JSON-compatible value
enum JSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    // Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode JSONValue"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    // Convenience initializers
    static func from(_ value: Any) -> JSONValue {
        switch value {
        case is NSNull, is NilType:
            return .null
        case let bool as Bool:
            return .bool(bool)
        case let number as Double:
            return .number(number)
        case let number as Int:
            return .number(Double(number))
        case let string as String:
            return .string(string)
        case let array as [Any]:
            return .array(array.map { from($0) })
        case let dict as [String: Any]:
            return .object(dict.mapValues { from($0) })
        default:
            return .null
        }
    }

    // Convenience getters
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    var numberValue: Double? {
        if case .number(let n) = self { return n }
        return nil
    }

    var intValue: Int? {
        if case .number(let n) = self { return Int(n) }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let a) = self { return a }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case .object(let o) = self { return o }
        return nil
    }

    subscript(key: String) -> JSONValue? {
        if case .object(let dict) = self { return dict[key] }
        return nil
    }

    subscript(index: Int) -> JSONValue? {
        if case .array(let arr) = self, index < arr.count { return arr[index] }
        return nil
    }
}

// MARK: - MCP Protocol Types

/// MCP Content Types
struct MCPContent: Codable {
    let type: String
    let text: String?
    let data: String?
    let mimeType: String?

    init(text: String) {
        self.type = "text"
        self.text = text
        self.data = nil
        self.mimeType = nil
    }

    init(data: String, mimeType: String) {
        self.type = "resource"
        self.text = nil
        self.data = data
        self.mimeType = mimeType
    }
}

/// MCP Tool Definition
struct MCPToolDefinition: Codable {
    let name: String
    let description: String
    let inputSchema: JSONValue

    init(name: String, description: String, inputSchema: [String: Any]) {
        self.name = name
        self.description = description
        self.inputSchema = .from(inputSchema)
    }
}

/// MCP Tool Result
struct MCPToolResult: Codable {
    let content: [MCPContent]
    let isError: Bool

    init(content: [MCPContent], isError: Bool = false) {
        self.content = content
        self.isError = isError
    }

    init(text: String, isError: Bool = false) {
        self.content = [MCPContent(text: text)]
        self.isError = isError
    }

    init(error: String) {
        self.content = [MCPContent(text: error)]
        self.isError = true
    }
}

// MARK: - MCP Server Info

struct MCPServerInfo: Codable {
    let name: String
    let version: String
    let protocolVersion: String = "2024-11-05"

    init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

struct MCPCapabilities: Codable {
    let tools: ToolsCapabilities

    struct ToolsCapabilities: Codable {
        let listChanged: Bool? = false
    }

    init() {
        self.tools = ToolsCapabilities(listChanged: false)
    }
}

// MARK: - MCP Methods

enum MCPMethod: String {
    case initialize = "initialize"
    case `static` = "notifications/initialized"
    case listTools = "tools/list"
    case callTool = "tools/call"
    case shutdown = "shutdown"
}