// swift-tools-version: 6.0
// This file is used for Swift Package Manager based development

import PackageDescription

let package = Package(
    name: "LooksmaxAI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LooksmaxAI",
            targets: ["LooksmaxAI"]
        )
    ],
    targets: [
        .target(
            name: "LooksmaxAI",
            path: "LooksmaxAI",
            exclude: ["Info.plist"]
        )
    ]
)
