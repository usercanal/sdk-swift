// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleEventExample",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(path: "../../..")
    ],
    targets: [
        .executableTarget(
            name: "SimpleEventExample",
            dependencies: [
                .product(name: "UserCanal", package: "sdk-swift")
            ],
            path: ".",
            sources: ["main.swift"]
        )
    ]
)