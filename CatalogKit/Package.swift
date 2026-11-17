// swift-tools-version: 6.2
import PackageDescription

// Same concurrency semantics as the app target's Approachable Concurrency setting.
let concurrencySettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "CatalogKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CatalogKit", targets: ["CatalogKit"]),
    ],
    targets: [
        .target(
            name: "CatalogKit",
            swiftSettings: concurrencySettings
        ),
        .testTarget(
            name: "CatalogKitTests",
            dependencies: ["CatalogKit"],
            resources: [.copy("Fixtures")],
            swiftSettings: concurrencySettings
        ),
    ]
)
