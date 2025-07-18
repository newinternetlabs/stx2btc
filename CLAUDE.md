# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
stx2btc is a Rust library that converts between Stacks (STX) and Bitcoin (BTC) native SegWit addresses. It includes FFI bindings for Swift, Kotlin, Python, and Ruby via UniFFI.

## Build Commands
```bash
# Default command: run tests and build
just
# or
just default

# Build the library (creates both .dylib and .a)
cargo build --release
# or
just build

# Run tests
cargo test
# or
just test

# Clean build artifacts and bindings
just clean

# Development workflow: clean, test, and update Swift bindings
just dev

# Generate language bindings (auto-builds if needed)
just swift    # Swift bindings (auto-syncs to Sources/)
just kotlin   # Kotlin bindings (untested)
just python   # Python bindings (untested)
just ruby     # Ruby bindings (untested)
just all      # All language bindings

# Build XCFramework for iOS (device + simulator)
just xcframework
# or
./build-xcframework.sh

# Quick check: validate Swift bindings and run tests
just check

# Full release workflow: clean, test, build everything
just release

# Create GitHub release with version tag
just publish v1.0.0
```

## Architecture
The library consists of:
- **Core library** (`src/lib.rs`): Two public functions `stx2btc` and `btc2stx`
- **FFI interface**: Uses UniFFI scaffolding with `src/lib.udl` defining the interface
- **Bindings generator**: `uniffi-bindgen.rs` creates language-specific bindings

Key technical constraints:
- Only supports mainnet addresses (hardcoded network versions)
- Only handles P2WPKH (version 0) Bitcoin addresses
- Maintains the same underlying HASH160 between formats

## Testing
Tests are inline in `src/lib.rs`. Currently has one integration test verifying round-trip conversion.

Run with: `cargo test`

## Generated Files
The `bindings/` directory (gitignored) contains generated language bindings:
- Swift: `stx2btc.swift`, `stx2btcFFI.h`, `stx2btcFFI.modulemap`
- Kotlin: `uniffi/stx2btc/stx2btc.kt`
- Python: `stx2btc.py`
- Ruby: `stx2btc.rb`

## Important Notes
- This is a proof-of-concept library, not for production use
- Bindings must be generated locally (not included in repo)
- Swift bindings are tested and documented; other languages are untested
- Uses cargo aliases defined in `.cargo/config.toml` for common operations