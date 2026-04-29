// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "iCanHazShortcut",
    platforms: [
        .macOS(.v11)
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "iCanHazShortcut",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
            ],
            path: "src"
        ),
    ]
)
