// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Stride",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "Stride",
            targets: ["Stride"]
        ),
        .executable(
            name: "stride-mcp",
            targets: ["stride-mcp"]
        ),
        .library(
            name: "StrideLib",
            targets: ["StrideLib"]
        )
    ],
    dependencies: [],
    targets: [
        // Library target containing all shared code (excludes the main app entry point)
        .target(
            name: "StrideLib",
            dependencies: [],
            path: "Sources/Stride",
            exclude: ["StrideApp.swift"]
        ),
        // macOS app executable
        .executableTarget(
            name: "Stride",
            dependencies: ["StrideLib"],
            path: "Sources/StrideApp",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        // MCP server executable
        .executableTarget(
            name: "stride-mcp",
            dependencies: ["StrideLib"],
            path: "Sources/stride-mcp"
        ),
        .testTarget(
            name: "StrideTests",
            dependencies: ["StrideLib"],
            path: "Tests/StrideTests"
        )
    ]
)