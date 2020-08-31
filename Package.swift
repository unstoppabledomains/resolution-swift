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
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.1"))
    ],
    targets: [
        .target(
            name: "Resolution",
            dependencies: ["CryptoSwift"],
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
