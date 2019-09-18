// swift-tools-version:5.1
//
// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import PackageDescription

let package = Package(
    name: "CombineGRPC",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "CombineGRPC",
            targets: ["CombineGRPC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0-alpha.6"),
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
