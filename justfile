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

# Generate all language bindings
all: swift kotlin python

# Clean generated files
clean:
    cargo clean
    rm -rf bindings

# Test the library
test:
    cargo test

# Development workflow: clean, test, build, and generate Swift bindings
dev: clean test swift 