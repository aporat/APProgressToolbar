// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APProgressToolbar",
    platforms: [
        .iOS(.v15),
        .tvOS(.v13),
        .macOS(.v12),
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
            path: "APProgressToolbar"
        ),
        .testTarget(
            name: "APProgressToolbarTests",
            dependencies: ["APProgressToolbar"]
        )
    ]
)
