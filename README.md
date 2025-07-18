# stx2btc

A example Rust library for converting between Stacks (STX) and Bitcoin (BTC) native SegWit addresses.

## WARNING

This library is only a proof concept example. Do not use in production.

## Features

- Convert Stacks addresses to Bitcoin native SegWit addresses (P2WPKH)
- Convert Bitcoin native SegWit addresses back to Stacks addresses (P2WPKH only)
- Maintains the same underlying HASH160 between address formats
- Only supports mainnet addresses

## Usage

### Basic Rust Usage

```rust
use stx2btc::{stx2btc, btc2stx};

let stx_address = "SP2V0G568F20Q1XCRT43XX8Q32V2DPMMYFHHBD8PP";
let btc_address = stx2btc(stx_address).unwrap();
println!("{}", btc_address); // bc1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy

let back_to_stx = btc2stx(&btc_address).unwrap();
println!("{}", back_to_stx); // SP2V0G568F20Q1XCRT43XX8Q32V2DPMMYFHHBD8PP
```

## Swift Package Manager Integration

This library is distributed as a Swift Package with both source code and binary components.

### Installation

#### Option 1: Swift Package Manager (Recommended)
Add this package to your Xcode project:
1. In Xcode: File → Add Package Dependencies
2. Enter the repository URL or local path
3. The package will automatically handle the XCFramework and Swift bindings

#### Option 2: Manual XCFramework Integration
For manual integration, build the XCFramework:

```bash
# Using just
just xcframework

# Or directly
./build-xcframework.sh
```

This creates an XCFramework at `target/xcframework/stx2btc.xcframework` containing:
- iOS device binary (arm64)
- iOS Simulator binary (arm64 for Apple Silicon)
- Headers and module map
- Swift bindings file

To use the XCFramework in your Xcode project:
1. Drag `target/xcframework/stx2btc.xcframework` into your Xcode project
2. Add `target/xcframework/stx2btc.swift` to your project
3. In your target's build settings, add to "Other Linker Flags": `-lc++ -lresolv`
4. Import and use as shown in the Swift usage examples below

### Keeping Bindings in Sync

For contributors: When modifying the Rust library, ensure Swift bindings stay in sync:

```bash
# After making Rust changes, sync the bindings
just sync-bindings                    # Updates and stages Swift bindings
git commit -m "Update Swift bindings" # Commit the changes

# Validate bindings before releases
just validate

# Full release workflow (validate, test, build)
just release
```

**Note**: Swift bindings in `Sources/stx2btc/` are committed to git and must be kept in sync with the Rust library.

### Generating Swift Bindings

#### Quick commands (recommended):

Using cargo aliases:
```bash
cargo build-libs && cargo swift-bindings
```

Or using [just](https://github.com/casey/just) (install with `cargo install just`):
```bash
just swift
```

#### Manual command (if needed):
```bash
# Build the library (creates both libstx2btc.dylib and libstx2btc.a)
cargo build --release

# Generate Swift bindings (uses .dylib for introspection, but bindings work with both .dylib and .a)
cargo run --bin uniffi-bindgen generate --library target/release/libstx2btc.dylib --language swift --out-dir bindings --no-format
```

This will create the `bindings/` directory with the Swift files.

**Note**: The binding generation uses the `.dylib` file to introspect the interface, but the generated Swift bindings work with both the dynamic library (`.dylib`) and static library (`.a`) - you choose which to link at build time in Xcode.

### Using in Swift

The generated Swift bindings are located in the `bindings/` directory. You can integrate them into your iOS/macOS project:

#### Option 1: Using static library (recommended for most cases)
Works on both macOS and iOS:
1. Copy `stx2btc.swift`, `stx2btcFFI.h`, and `stx2btcFFI.modulemap` to your Xcode project
2. Copy the `libstx2btc.a` static library to your project
3. Link the static library in your Xcode project settings
4. Use the functions in your Swift code

#### Option 2: Using dynamic library (macOS only)
For macOS development/testing when you want smaller binaries:
1. Copy `stx2btc.swift`, `stx2btcFFI.h`, and `stx2btcFFI.modulemap` to your Xcode project
2. Copy the `libstx2btc.dylib` library to your project
3. Use the functions in your Swift code

**Note**: iOS requires the static library (`.a`) for App Store distribution, but macOS can use either.

```swift
import Foundation

do {
    let btcAddress = try stx2btc(stxAddress: "SP2V0G568F20Q1XCRT43XX8Q32V2DPMMYFHHBD8PP")
    print(btcAddress) // bc1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy
    
    let backToStx = try btc2stx(btcAddress: btcAddress)
    print(backToStx) // SP2V0G568F20Q1XCRT43XX8Q32V2DPMMYFHHBD8PP
} catch {
    print("Conversion error: \(error)")
}
```

### Error Handling

The Swift bindings include proper error handling with the `ConversionError` enum:

```swift
enum ConversionError: Error {
    case SegwitDecode(String)
    case UnsupportedVersion
    case SegwitEncode(String)
}
```

## Other Language Bindings (Untested)

UniFFI supports generating bindings for additional languages including kotlin, python and ruby. These are available but **untested**:

### Quick commands:
```bash
# Using cargo aliases
cargo kotlin-bindings  # Kotlin/Android
cargo python-bindings  # Python
cargo ruby-bindings    # Ruby

# Using just
just kotlin   # Kotlin/Android
just python   # Python  
just ruby     # Ruby
just all      # All languages (Swift, Kotlin, Python, Ruby)
```

See the [UniFFI documentation](https://mozilla.github.io/uniffi-rs/) for more details on supported languages and usage.
