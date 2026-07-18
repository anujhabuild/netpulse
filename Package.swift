// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpeedWidth",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "SpeedWidthCore"
        ),
        .executableTarget(
            name: "SpeedWidth",
            dependencies: ["SpeedWidthCore"]
        ),
        .testTarget(
            name: "SpeedWidthCoreTests",
            dependencies: ["SpeedWidthCore"]
        )
    ]
)
