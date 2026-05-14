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
        .package(path: "../../Shared/AppDomain"),
        .package(path: "../../Core/UI/DesignSystem"),
        .package(path: "../../Core/UI/UIComponents")
    ],
    targets: [
        .target(
            name: "FeatureLogin",
            dependencies: [
                "AppDomain",
                "DesignSystem",
                "UIComponents"
            ],
            path: "Sources/FeatureLogin",
            linkerSettings: [

            ]
        ),
        .testTarget(
            name: "FeatureLoginTests",
            dependencies: [
                "FeatureLogin",
                "AppDomain",
                "DesignSystem",
                "UIComponents"
            ],
            path: "Tests/FeatureLoginTests",
            linkerSettings: [

            ]
        )
    ]
)
