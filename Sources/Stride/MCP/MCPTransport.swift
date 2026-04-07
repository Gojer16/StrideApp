import Foundation

/// MCP Transport using stdio for communication
/// Reads JSON-RPC messages from stdin and writes responses to stdout
final class MCPTransport {
    private let stdin: FileHandle
    private let stdout: FileHandle
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var isRunning = false
    private let runningLock = NSLock()

    init(stdin: FileHandle = .standardInput, stdout: FileHandle = .standardOutput) {
        self.stdin = stdin
        self.stdout = stdout
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        // Configure encoder for pretty printing (easier debugging)
        encoder.outputFormatting = [.sortedKeys]
    }

    /// Start listening for incoming messages
    func start(handler: @escaping (JSONRPCRequest) -> JSONRPCResponse?) {
        runningLock.lock()
        isRunning = true
        runningLock.unlock()

        // Read from stdin line by line
        var buffer = Data()

        while true {
            runningLock.lock()
            let running = isRunning
            runningLock.unlock()

            if !running { break }

            // Read available data
            let data = stdin.availableData

            if data.isEmpty {
                // EOF reached
                break
            }

            buffer.append(data)

            // Process complete lines (messages)
            while let newlineIndex = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let lineData = buffer[0..<newlineIndex]
                buffer = buffer[(buffer.index(after: newlineIndex))...]

                if let lineString = String(data: lineData, encoding: .utf8),
                   !lineString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    processMessage(lineString, handler: handler)
                }
            }
        }
    }

    /// Stop the transport
    func stop() {
        runningLock.lock()
        isRunning = false
        runningLock.unlock()
    }

    /// Process a single message
    private func processMessage(_ message: String, handler: (JSONRPCRequest) -> JSONRPCResponse?) {
        // Parse the JSON-RPC request
        guard let data = message.data(using: .utf8) else {
            sendError(JSONRPCError.parseError, id: nil)
            return
        }

        do {
            let request = try decoder.decode(JSONRPCRequest.self, from: data)
            if let response = handler(request) {
                send(response: response)
            }
        } catch {
            sendError(JSONRPCError.parseError, id: nil)
        }
    }

    /// Send a response to stdout
    func send(response: JSONRPCResponse) {
        do {
            let data = try encoder.encode(response)
            stdout.write(data)
            stdout.write(Data([UInt8(ascii: "\n")]))
            stdout.synchronizeFile()
        } catch {
            // Can't do much if encoding fails
            print("Error encoding response: \(error)", to: &stderr)
        }
    }

    /// Send an error response
    private func sendError(_ error: JSONRPCError, id: Int?) {
        let response = JSONRPCResponse(id: id, error: error)
        send(response: response)
    }

    /// Send a notification (no id)
    func sendNotification(method: String, params: [String: JSONValue]? = nil) {
        let response = JSONRPCResponse(id: nil, result: .object([
            "jsonrpc": .string("2.0"),
            "method": .string(method),
            "params": params.map { .object($0) } ?? .null
        ]))
        send(response: response)
    }
}

// MARK: - Helper Extensions

extension FileHandle {
    func synchronizeFile() {
        // Ensure data is written to the underlying file
        try? self.synchronize()
    }
}

// MARK: - Async Transport Support

extension MCPTransport {
    /// Start with async/await support
    func startAsync(handler: @escaping (JSONRPCRequest) async -> JSONRPCResponse?) async {
        await withCheckedContinuation { continuation in
            start { request in
                // We need to bridge sync to async here
                // For now, this is a simple synchronous implementation
                // In production, you might use Task and continuation
                nil
            }
        }
    }
}