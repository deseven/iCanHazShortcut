// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "iCanHazShortcut",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/mattt/swift-toml.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "iCanHazShortcut",
            dependencies: [
                .product(name: "TOML", package: "swift-toml"),
            ],
            path: "src"
        ),
    ]
)
