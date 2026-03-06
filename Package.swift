// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "LifeAnalyticsAIDependencies",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "DependencySmoke", targets: ["DependencySmoke"])
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/malcommac/SwiftDate", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "DependencySmoke",
            dependencies: [
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "SwiftDate", package: "SwiftDate")
            ],
            path: "SPM/DependencySmoke"
        )
    ]
)
