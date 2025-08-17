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
            url: "https://github.com/newinternetlabs/stx2btc/releases/download/v0.5.0/stx2btc.xcframework.zip",
            checksum: "158715af0e673eb40a932252a53bab422ea77ededfe2b70f29aa913fcc3485d6"
        ),
        .target(
            name: "stx2btc",
            dependencies: ["stx2btcFFI"],
            path: "Sources/stx2btc"
        ),
    ]
)
