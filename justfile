# Build both static and dynamic libraries
build:
    cargo build-libs

# Generate Swift bindings (builds first if needed)
swift: build
    cargo swift-bindings

# Generate Kotlin bindings (builds first if needed)
kotlin: build
    cargo kotlin-bindings

# Generate Python bindings (builds first if needed)
python: build
    cargo python-bindings

# Generate Ruby bindings (builds first if needed)
ruby: build
    cargo ruby-bindings

# Generate all language bindings
all: swift kotlin python ruby

# Clean generated files
clean:
    cargo clean
    rm -rf bindings

# Test the library
test:
    cargo test

# Development workflow: clean, test, build, and generate Swift bindings
dev: clean test swift

# Build XCFramework for iOS (device + simulator)
xcframework:
    ./build-xcframework.sh

# Validate that Swift bindings are in sync with Rust library
validate:
    ./validate-bindings.sh

# Sync Swift bindings to Sources directory (run after Rust changes)
sync-bindings:
    cargo build-libs
    cargo swift-bindings
    cp bindings/stx2btc.swift Sources/stx2btc/
    git add Sources/stx2btc/stx2btc.swift
    @echo "✅ Swift bindings updated and staged for commit"
    @echo "Ready to commit with: git commit -m 'Update Swift bindings'"

# Full release workflow: validate, test, build XCFramework
release: validate test xcframework 