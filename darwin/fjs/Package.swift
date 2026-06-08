// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "fjs",
    platforms: [
        .iOS("12.0"),
        .macOS("10.14")
    ],
    products: [
        .library(name: "fjs", targets: ["FjsPlugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "FjsPlugin",
            dependencies: [
                "FjsBinary",
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        ),
        .binaryTarget(
            name: "FjsBinary",
            path: "Binaries/fjs.xcframework"
        )
    ]
)
