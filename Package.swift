// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnstoppableDomainsResolution",
    platforms: [.macOS(.v10_15), .iOS(.v13) ],
    products: [
        .library(
            name: "UnstoppableDomainsResolution",
            type: nil,
            targets: ["UnstoppableDomainsResolution"])
    ],
    dependencies: [
        .package(url: "https://github.com/deczer/EthereumABI", .upToNextMinor(from: "1.0.1")),
        .package(url: "https://github.com/keefertaylor/Base58Swift.git", .upToNextMinor(from: "2.1.0"))
    ],
    targets: [
        .target(
            name: "UnstoppableDomainsResolution",
            dependencies: ["EthereumABI", "Base58Swift"],
            resources: [
                .process("Resources/CNS/cnsProxyReader.json"),
                .process("Resources/CNS/cnsRegistry.json"),
                .process("Resources/CNS/cnsResolver.json"),
                .process("Resources/ENS/ensRegistry.json"),
                .process("Resources/ENS/ensResolver.json")
            ],
            swiftSettings: [.define("INSIDE_PM")]
        ),
        .testTarget(
            name: "ResolutionTests",
            dependencies: ["UnstoppableDomainsResolution"],
            exclude:["Info.plist"],
            swiftSettings: [.define("INSIDE_PM")]
        )
    ]
)
