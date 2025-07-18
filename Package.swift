// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "stx2btc",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "stx2btc",
            targets: ["stx2btc"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "stx2btcFFI",
            url: "https://github.com/newinternetlabs/stx2btc/releases/download/v0.3.1/stx2btc.xcframework.zip",
            checksum: "5337bbca90b68698a33fca6647aa42f8557781f60404bc14401a0dbed6298c00"
        ),
        .target(
            name: "stx2btc",
            dependencies: ["stx2btcFFI"],
            path: "Sources/stx2btc"
        ),
    ]
)
