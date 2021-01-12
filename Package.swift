// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiveChat",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "LiveChat",
            targets: ["LiveChat"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LiveChat",
            dependencies: [],
            path: "Sources",
            exclude: ["Info.plist"],
            resources: [.process("LiveChatWidget.js")],
            swiftSettings: [.define("SwiftPM")])
    ]
)
