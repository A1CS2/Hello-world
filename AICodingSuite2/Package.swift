// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AICodingSuite",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AICodingSuite", targets: ["AICodingSuite"])
    ],
    dependencies: [
        // Future dependencies:
        // .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0"),
        // .package(url: "https://github.com/SwiftGen/SwiftGen", from: "6.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "AICodingSuite",
            dependencies: [],
            path: "AICodingSuite",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AICodingSuiteTests",
            dependencies: ["AICodingSuite"],
            path: "Tests/AICodingSuiteTests"
        )
    ]
)
