// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APProgressToolbar",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "APProgressToolbar",
            targets: ["APProgressToolbar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/aporat/GTProgressBar.git", from: "1.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "APProgressToolbar",
            dependencies: ["GTProgressBar", "SnapKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "APProgressToolbarTests",
            dependencies: ["APProgressToolbar"],
            path: "Tests"
        )
    ]
)
