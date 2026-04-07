import Foundation
import StrideLib

// MARK: - MCP Server Entry Point

/// Main entry point for the Stride MCP Server
/// This server exposes Stride's productivity data to AI agents via the MCP protocol

print("Stride MCP Server starting...", to: &stderr)
print("Protocol: MCP 2024-11-05", to: &stderr)

// Initialize databases
_ = UsageDatabase.shared
_ = HabitDatabase.shared
_ = WeeklyLogDatabase.shared

// Start the MCP server
let server = MCPServer(
    name: "Stride MCP Server",
    version: "1.0.0"
)

// Run until shutdown
server.start()