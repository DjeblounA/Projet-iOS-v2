// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftApp",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        // Framework web Hummingbird 2
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        // Bibliothèque SQLite pour Swift
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "SQLite", package: "SQLite.swift"),
            ]
        )
    ]
)
