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
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CleverPush",
            targets: ["CleverPush"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CleverPush",
            path: "CleverPush/CleverPush",
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
//        .testTarget(
//            name: "CleverPushTests",
//            dependencies: ["CleverPush"],
//            path:"Tests"),
    ]
)
