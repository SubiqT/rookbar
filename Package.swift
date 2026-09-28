// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "rookbar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "rookbar", targets: ["rookbar"]),
    ],
    targets: [
        .target(name: "RookbarCore"),
        .executableTarget(
            name: "rookbar",
            dependencies: ["RookbarCore"]
        ),
        .testTarget(
            name: "RookbarCoreTests",
            dependencies: ["RookbarCore"]
        ),
    ]
)
