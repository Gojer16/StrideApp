// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Stride",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "Stride",
            targets: ["Stride"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Stride",
            dependencies: [],
            path: "Sources/Stride"
        )
    ]
)