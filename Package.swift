// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LeParquet",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "leparquet", targets: ["leparquet"]),
        .library(name: "LeParquetFramework", targets: ["LeParquetFramework"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "4.0.4")),
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "0.4.1")),
    ],
    targets: [
        .target(
            name: "leparquet",
            dependencies: [
                "LeParquetFramework",
            ]
        ),
        .target(
            name: "LeParquetFramework",
            dependencies: [
                "Yams",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "leparquetTests",
            dependencies: ["LeParquetFramework"],
            resources: [
                .copy("config.yaml"),
            ]
        ),
    ]
)
