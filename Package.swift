// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GeotabMobileSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GeotabMobileSDK",
            targets: ["GeotabMobileSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/groue/GRMustache.swift", from: "4.0.1"),
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.1.0"),
        .package(url: "https://github.com/Geotab/mobile-swift-rison", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GeotabMobileSDK",
            dependencies: [.product(name: "Mustache", package: "GRMustache.swift"),
                           .product(name: "Reachability", package: "Reachability.swift"),
                           .product(name: "SwiftRison", package: "mobile-swift-rison")],
            exclude: [
                "native-sdk.d.ts"],
            resources: [
                .process("Assets")]),
        .testTarget(
            name: "GeotabMobileSDKTests",
            dependencies: ["GeotabMobileSDK"],
            exclude: ["Info.plist", "rulesets.json"]),
    ]
)
