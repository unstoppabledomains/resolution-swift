// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Resolution",
    products: [
        .library(
            name: "Resolution",
            targets: ["Resolution"])
    ],
    dependencies: [
        .package(url: "https://github.com/deczer/EthereumABI", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/keefertaylor/Base58Swift.git", .upToNextMinor(from: "2.1.0")),
    ],
    targets: [
        .target(
            name: "Resolution",
            dependencies: ["EthereumABI", "Base58Swift"],
            resources: [
                .copy("ABI/CNS/cnsRegistry.json"),
                .copy("ABI/CNS/cnsResolver.json")
            ]
        ),
        .testTarget(
            name: "ResolutionTests",
            dependencies: ["Resolution"],
            exclude:["Info.plist"],
            resources: [
                .copy("ABI/CNS/cnsRegistry.json"),
                .copy("ABI/CNS/cnsResolver.json")
            ]
        )
    ]
)
