// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APProgressToolbar",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "APProgressToolbar",
            targets: ["APProgressToolbar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "APProgressToolbar",
            dependencies: ["SnapKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "APProgressToolbarTests",
            dependencies: ["APProgressToolbar"],
            path: "Tests"
        )
    ]
)
