// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "CleverPush",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "CleverPush",
            targets: ["CleverPush"]
        ),
        .library(
            name: "CleverPushExtension",
            targets: ["CleverPushExtension"]
        )
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
                .linkedFramework("ImageIO"),
                .linkedFramework("MobileCoreServices"),
                .linkedFramework("MessageUI"),
            ]
        ),
        .target(
            name: "CleverPushExtension",
            dependencies: ["CleverPush"],
            path: "CleverPushExtension",
            publicHeadersPath: "."
        )
    ]
)
