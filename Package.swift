// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TZExpand",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TZExpand", targets: ["TZExpand"]),
        .library(name: "TZExpandCore", targets: ["TZExpandCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "TZExpandCore",
            path: "Sources/TZExpandCore"
        ),
        .executableTarget(
            name: "TZExpand",
            dependencies: ["TZExpandCore"],
            path: "Sources/TZExpand"
        ),
        .testTarget(
            name: "TZExpandCoreTests",
            dependencies: [
                "TZExpandCore",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/TZExpandCoreTests"
        ),
    ]
)
