// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    dependencies: [
        .package(name: "ClampedInteger", url: "http://github.com/berikv/ClampedInteger", from: "1.0.5")
    ],
    targets: [
        .target(
            name: "VirtualTimeScheduler",
            dependencies: ["ClampedInteger"]),
        .testTarget(
            name: "VirtualTimeSchedulerTests",
            dependencies: ["VirtualTimeScheduler"]),
    ]
)
