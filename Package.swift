// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Resolution",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Resolution",
            targets: ["Resolution"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Resolution",
            dependencies: ["CryptoSwift"]
//            resources: [
//                .process("cnsRegistry.json"),
//                .process("cnsResolver.json"),
//            ]
        ),
        .testTarget(
            name: "ResolutionTests",
            dependencies: ["Resolution"]),
    ]
)
