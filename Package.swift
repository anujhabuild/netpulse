// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NetPulse",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "NetPulseCore"
        ),
        .executableTarget(
            name: "NetPulse",
            dependencies: ["NetPulseCore"]
        ),
        .testTarget(
            name: "NetPulseCoreTests",
            dependencies: ["NetPulseCore"]
        )
    ]
)
