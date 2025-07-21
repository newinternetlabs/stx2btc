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
            url: "https://github.com/newinternetlabs/stx2btc/releases/download/v0.4.0/stx2btc.xcframework.zip",
            checksum: "030d1865ff9ebb72779b8debbb87f2d8be35011ce1097b29aac85cbc0910ea04"
        ),
        .target(
            name: "stx2btc",
            dependencies: ["stx2btcFFI"],
            path: "Sources/stx2btc"
        ),
    ]
)
