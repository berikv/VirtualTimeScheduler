// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "VirtualTimeScheduler",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "VirtualTimeScheduler",
            targets: ["VirtualTimeScheduler"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VirtualTimeScheduler",
            dependencies: []),
        .testTarget(
            name: "VirtualTimeSchedulerTests",
            dependencies: ["VirtualTimeScheduler"]),
    ]
)
