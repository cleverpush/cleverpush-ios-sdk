// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CleverPush",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "CleverPush",
            targets: ["CleverPush"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CleverPush",
            path: "CleverPush",
            exclude: [
                "Info.plist"
            ],
            resources: [
                .process("Resources"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Source"),
                .headerSearchPath("Source/DWAlertController"),
            ],
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UIKit"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("StoreKit"),
                .linkedFramework("WebKit"),
                .linkedFramework("JavaScriptCore"),
                .linkedFramework("SafariServices"),

            ]),
    ]
)
