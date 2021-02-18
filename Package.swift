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
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "0.3.2")),
//        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.31.0")),
//        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.2"),
//
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "leparquet",
            dependencies: [
                "LeParquetFramework",
                "Yams",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "LeParquetFramework",
            dependencies: []
        ),
        .testTarget(
            name: "leparquetTests",
            dependencies: []
        ),
    ]
)
