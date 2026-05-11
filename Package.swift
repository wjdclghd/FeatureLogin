// swift-tools-version: 6.0
//
//  Package.swift
//  FeatureLogin
//
//  Created by jch on 4/27/26.
//

import PackageDescription

let package = Package(
    name: "FeatureLogin",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "FeatureLogin",
            targets: ["FeatureLogin"]
        )
    ],
    dependencies: [
        .package(path: "../../Core/UI/DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureLogin",
            dependencies: [
                "DesignSystem"
            ],
            path: "Sources/FeatureLogin",
            linkerSettings: [

            ]
        ),
        .testTarget(
            name: "FeatureLoginTests",
            dependencies: [
                "FeatureLogin",
                "DesignSystem"
            ],
            path: "Tests/FeatureLoginTests",
            linkerSettings: [

            ]
        )
    ]
)
