// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "stx2btc",
    platforms: [
        .iOS(.v13),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "stx2btcFFI",
            targets: ["stx2btcFFI"]),
        .library(
            name: "stx2btc",
            targets: ["stx2btc"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "stx2btcFFI",
            path: "target/xcframework/stx2btc.xcframework"
        ),
        .target(
            name: "stx2btc",
            dependencies: ["stx2btcFFI"],
            path: "Sources/stx2btc"
        ),
    ]
)
