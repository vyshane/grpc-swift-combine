// swift-tools-version:5.1
//
// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import PackageDescription

let package = Package(
    name: "CombineGRPC",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "CombineGRPC",
            targets: ["CombineGRPC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", .exact("1.9.0"))
    ],
    targets: [
        .target(
            name: "CombineGRPC",
            dependencies: ["GRPC"]),
        .testTarget(
            name: "CombineGRPCTests",
            dependencies: ["CombineGRPC"]),
    ]
)
