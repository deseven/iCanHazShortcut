// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "iCanHazShortcut",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/mattt/swift-toml.git", from: "2.0.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "iCanHazShortcut",
            dependencies: [
                .product(name: "TOML", package: "swift-toml"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
            ],
            path: "src"
        ),
    ]
)
