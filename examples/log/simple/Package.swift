// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleLogExample",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(path: "../../..")
    ],
    targets: [
        .executableTarget(
            name: "SimpleLogExample",
            dependencies: [
                .product(name: "UserCanal", package: "sdk-swift")
            ],
            path: ".",
            sources: ["main.swift"]
        )
    ]
)