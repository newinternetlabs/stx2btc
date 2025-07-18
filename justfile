# Default command: run tests and build
default: test build

# Build both static and dynamic libraries
build:
    cargo build-libs

# Test the library
test:
    cargo test

# Clean generated files
clean:
    cargo clean
    rm -rf bindings

# Generate Swift bindings and sync to Sources
swift: build
    cargo swift-bindings
    cp bindings/stx2btc.swift Sources/stx2btc/
    git add Sources/stx2btc/stx2btc.swift
    @echo "✅ Swift bindings updated and staged for commit"

# Generate Kotlin bindings
kotlin: build
    cargo kotlin-bindings

# Generate Python bindings
python: build
    cargo python-bindings

# Generate Ruby bindings
ruby: build
    cargo ruby-bindings

# Generate all language bindings
all: swift kotlin python ruby

# Build XCFramework for iOS (device + simulator)
xcframework:
    ./build-xcframework.sh

# Quick check: validate Swift bindings and run tests
check:
    ./validate-bindings.sh
    cargo test

# Development workflow: clean, test, and update Swift bindings
dev: clean test swift

# Full release workflow: clean, test, build everything
release: clean test build all xcframework 