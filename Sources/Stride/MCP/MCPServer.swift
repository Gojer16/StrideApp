import Foundation

// MARK: - MCP Server

/// Main MCP Server class that handles JSON-RPC requests and routes to appropriate tools
final class MCPServer {
    private let transport: MCPTransport
    private let serverInfo: MCPServerInfo
    private let capabilities: MCPCapabilities
    private var tools: [String: MCPTool] = [:]

    // MARK: - Initialization

    init(name: String = "Stride MCP Server", version: String = "1.0.0") {
        self.transport = MCPTransport()
        self.serverInfo = MCPServerInfo(name: name, version: version)
        self.capabilities = MCPCapabilities()

        registerAllTools()
    }

    // MARK: - Tool Registration

    private func registerAllTools() {
        // Usage Stats Tools
        registerTool(GetTodayStatsTool())
        registerTool(GetAppUsageTool())
        registerTool(GetBrowserDomainsTool())
        registerTool(GetSessionsTool())
        registerTool(GetCategoriesTool())
        registerTool(AssignAppCategoryTool())
        registerTool(CreateCategoryTool())

        // Habit Tools
        registerTool(GetHabitsTool())
        registerTool(GetHabitEntriesTool())
        registerTool(GetHabitStreakTool())
        registerTool(CreateHabitTool())
        registerTool(UpdateHabitTool())
        registerTool(LogHabitEntryTool())
        registerTool(DeleteHabitTool())

        // Weekly Log Tools
        registerTool(GetWeeklyEntriesTool())
        registerTool(GetWeeklySummaryTool())
        registerTool(CreateLogEntryTool())
        registerTool(UpdateLogEntryTool())
        registerTool(DeleteLogEntryTool())
        registerTool(GetWeeklyCategoriesTool())
        registerTool(SetCategoryColorTool())
    }

    private func registerTool(_ tool: MCPTool) {
        tools[tool.name] = tool
    }

    // MARK: - Server Lifecycle

    func start() {
        // Send server info to stderr for debugging
        print("Starting \(serverInfo.name) v\(serverInfo.version)", to: &stderr)

        // Start listening for requests
        transport.start { [weak self] request in
            guard let self = self else { return nil }
            return self.handleRequest(request)
        }
    }

    func stop() {
        transport.stop()
    }

    // MARK: - Request Handling

    private func handleRequest(_ request: JSONRPCRequest) -> JSONRPCResponse? {
        switch request.method {
        case MCPMethod.initialize.rawValue:
            return handleInitialize(request)

        case MCPMethod.listTools.rawValue:
            return handleListTools(request)

        case MCPMethod.callTool.rawValue:
            return handleCallTool(request)

        case MCPMethod.shutdown.rawValue:
            return handleShutdown(request)

        default:
            return JSONRPCResponse(
                id: request.id,
                error: JSONRPCError.methodNotFound
            )
        }
    }

    // MARK: - Initialize Handler

    private func handleInitialize(_ request: JSONRPCRequest) -> JSONRPCResponse {
        let result: [String: JSONValue] = [
            "protocolVersion": .string(serverInfo.protocolVersion),
            "capabilities": .object([
                "tools": .object([
                    "listChanged": .bool(false)
                ])
            ]),
            "serverInfo": .object([
                "name": .string(serverInfo.name),
                "version": .string(serverInfo.version)
            ])
        ]

        return JSONRPCResponse(
            id: request.id,
            result: .object(result)
        )
    }

    // MARK: - List Tools Handler

    private func handleListTools(_ request: JSONRPCRequest) -> JSONRPCResponse {
        let toolsData = tools.values.map { tool -> JSONValue in
            return .object([
                "name": .string(tool.name),
                "description": .string(tool.description),
                "inputSchema": tool.schemaAsJSON()
            ])
        }

        let result: [String: JSONValue] = [
            "tools": .array(toolsData)
        ]

        return JSONRPCResponse(
            id: request.id,
            result: .object(result)
        )
    }

    // MARK: - Call Tool Handler

    private func handleCallTool(_ request: JSONRPCRequest) -> JSONRPCResponse {
        guard let params = request.params,
              let toolNameValue = params["name"],
              case .string(let toolName) = toolNameValue else {
            return JSONRPCResponse(
                id: request.id,
                error: JSONRPCError.invalidParams
            )
        }

        guard let tool = tools[toolName] else {
            return JSONRPCResponse(
                id: request.id,
                error: JSONRPCError(
                    code: -32601,
                    message: "Tool not found: \(toolName)"
                )
            )
        }

        // Extract arguments
        var arguments: [String: Any] = [:]
        if let argsValue = params["arguments"],
           case .object(let args) = argsValue {
            arguments = args.mapValues { value -> Any in
                switch value {
                case .null: return NSNull()
                case .bool(let b): return b
                case .number(let n): return n
                case .string(let s): return s
                case .array(let a): return a.map { jsonValueToAny($0) }
                case .object(let o): return o.mapValues { jsonValueToAny($0) }
                }
            }
        }

        // Execute tool asynchronously
        let result = waitForToolExecution(tool: tool, arguments: arguments)

        return JSONRPCResponse(
            id: request.id,
            result: result
        )
    }

    private func waitForToolExecution(tool: MCPTool, arguments: [String: Any]) -> JSONValue {
        let semaphore = DispatchSemaphore(value: 0)
        var toolResult: MCPToolResult?

        Task {
            toolResult = await tool.execute(parameters: arguments)
            semaphore.signal()
        }

        semaphore.wait()

        guard let result = toolResult else {
            return .object([
                "content": .array([.object([
                    "type": .string("text"),
                    "text": .string("Error: Tool execution timed out")
                ])],
                "isError": .bool(true)
            ])
        }

        return encodeToolResult(result)
    }

    private func encodeToolResult(_ result: MCPToolResult) -> JSONValue {
        var contentArray: [JSONValue] = []

        for content in result.content {
            var contentDict: [String: JSONValue] = [
                "type": .string(content.type)
            ]
            if let text = content.text {
                contentDict["text"] = .string(text)
            }
            if let data = content.data {
                contentDict["data"] = .string(data)
            }
            if let mimeType = content.mimeType {
                contentDict["mimeType"] = .string(mimeType)
            }
            contentArray.append(.object(contentDict))
        }

        return .object([
            "content": .array(contentArray),
            "isError": .bool(result.isError)
        ])
    }

    // MARK: - Shutdown Handler

    private func handleShutdown(_ request: JSONRPCResponse) -> JSONRPCResponse {
        // Clean shutdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.stop()
            exit(0)
        }

        return JSONRPCResponse(
            id: request.id,
            result: .null
        )
    }

    // MARK: - Helpers

    private func jsonValueToAny(_ value: JSONValue) -> Any {
        switch value {
        case .null: return NSNull()
        case .bool(let b): return b
        case .number(let n): return n
        case .string(let s): return s
        case .array(let a): return a.map { jsonValueToAny($0) }
        case .object(let o): return o.mapValues { jsonValueToAny($0) }
        }
    }
}