#!/bin/bash
set -e

# Build script for creating an XCFramework containing stx2btc for iOS, iOS Simulator, and macOS

echo "🏗️  Building stx2btc XCFramework..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="stx2btc"
FRAMEWORK_NAME="${PROJECT_NAME}"
BUILD_DIR="target/xcframework-build"
OUTPUT_DIR="target/xcframework"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}"

# Function to check if a Rust target is installed
check_rust_target() {
    local target=$1
    if ! rustup target list --installed | grep -q "$target"; then
        echo -e "${YELLOW}Installing Rust target: $target${NC}"
        rustup target add "$target"
    fi
}

# Install required Rust targets
echo "📦 Checking Rust targets..."
check_rust_target "aarch64-apple-ios"
check_rust_target "aarch64-apple-ios-sim"
check_rust_target "aarch64-apple-darwin"
check_rust_target "x86_64-apple-darwin"

# Build for iOS device (arm64)
echo -e "${GREEN}📱 Building for iOS device (arm64)...${NC}"
cargo build --release --target aarch64-apple-ios
mkdir -p "${BUILD_DIR}/ios"
cp "target/aarch64-apple-ios/release/lib${PROJECT_NAME}.a" "${BUILD_DIR}/ios/"

# Build for iOS Simulator (arm64)
echo -e "${GREEN}📱 Building for iOS Simulator (arm64)...${NC}"
cargo build --release --target aarch64-apple-ios-sim
mkdir -p "${BUILD_DIR}/ios-simulator"
cp "target/aarch64-apple-ios-sim/release/lib${PROJECT_NAME}.a" "${BUILD_DIR}/ios-simulator/"

# Build for macOS (arm64)
echo -e "${GREEN}💻 Building for macOS (arm64)...${NC}"
cargo build --release --target aarch64-apple-darwin
mkdir -p "${BUILD_DIR}/macos-arm64"
cp "target/aarch64-apple-darwin/release/lib${PROJECT_NAME}.a" "${BUILD_DIR}/macos-arm64/"

# Build for macOS (x86_64)
echo -e "${GREEN}💻 Building for macOS (x86_64)...${NC}"
cargo build --release --target x86_64-apple-darwin
mkdir -p "${BUILD_DIR}/macos-x86_64"
cp "target/x86_64-apple-darwin/release/lib${PROJECT_NAME}.a" "${BUILD_DIR}/macos-x86_64/"

# Create universal macOS library
echo -e "${GREEN}🔗 Creating universal macOS library...${NC}"
mkdir -p "${BUILD_DIR}/macos"
lipo -create \
    "${BUILD_DIR}/macos-arm64/lib${PROJECT_NAME}.a" \
    "${BUILD_DIR}/macos-x86_64/lib${PROJECT_NAME}.a" \
    -output "${BUILD_DIR}/macos/lib${PROJECT_NAME}.a"

# Generate Swift bindings (always regenerate to ensure fresh bindings)
echo "🔧 Generating Swift bindings..."
# First build for the host platform to generate bindings
cargo build-libs
cargo swift-bindings

# Prepare headers and module map
echo "📄 Preparing headers and module map..."
mkdir -p "${BUILD_DIR}/Headers"
cp "bindings/${PROJECT_NAME}FFI.h" "${BUILD_DIR}/Headers/"

# Create module map
cat > "${BUILD_DIR}/Headers/module.modulemap" << EOF
module ${PROJECT_NAME}FFI {
    header "${PROJECT_NAME}FFI.h"
    export *
}
EOF

# Create XCFramework
echo -e "${GREEN}📦 Creating XCFramework...${NC}"
xcodebuild -create-xcframework \
    -library "${BUILD_DIR}/ios/lib${PROJECT_NAME}.a" \
    -headers "${BUILD_DIR}/Headers" \
    -library "${BUILD_DIR}/ios-simulator/lib${PROJECT_NAME}.a" \
    -headers "${BUILD_DIR}/Headers" \
    -library "${BUILD_DIR}/macos/lib${PROJECT_NAME}.a" \
    -headers "${BUILD_DIR}/Headers" \
    -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

# Copy Swift bindings alongside the XCFramework and to Sources
echo "📋 Copying Swift bindings..."
cp "bindings/${PROJECT_NAME}.swift" "${OUTPUT_DIR}/"
cp "bindings/${PROJECT_NAME}.swift" "Sources/${PROJECT_NAME}/"

echo "📋 Updating Swift bindings in Sources..."
echo "Swift bindings updated in Sources/${PROJECT_NAME}/"

# Create a README for the XCFramework
cat > "${OUTPUT_DIR}/README.md" << EOF
# ${PROJECT_NAME} XCFramework

This XCFramework contains the ${PROJECT_NAME} library for iOS, iOS Simulator, and macOS.

## Contents

- \`${FRAMEWORK_NAME}.xcframework\` - The XCFramework containing:
  - iOS device binary (arm64)
  - iOS Simulator binary (arm64)
  - macOS universal binary (arm64 + x86_64)
  - Headers and module map
- \`${PROJECT_NAME}.swift\` - Swift bindings

## Integration

### Xcode Projects
1. Drag the \`${FRAMEWORK_NAME}.xcframework\` into your Xcode project
2. Add \`${PROJECT_NAME}.swift\` to your project
3. In your target's build settings:
   - Add to "Other Linker Flags": \`-lc++ -lresolv\`
4. Import and use:
   \`\`\`swift
   import ${PROJECT_NAME}FFI
   
   // Use the functions from ${PROJECT_NAME}.swift
   \`\`\`

### Swift Package Manager
Add as a dependency in your Package.swift:
\`\`\`swift
dependencies: [
    .package(url: "https://github.com/newinternetlabs/stx2btc", branch: "master")
]
\`\`\`

## Supported Platforms and Architectures

- **iOS Device**: arm64 (iOS 13.0+)
- **iOS Simulator**: arm64 (Apple Silicon Macs)
- **macOS**: arm64 + x86_64 universal (macOS 11.0+)

## Platform Requirements

- iOS 13.0+
- macOS 11.0+
EOF

echo -e "${GREEN}✅ XCFramework created successfully!${NC}"
echo "📍 Location: ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
echo "📝 Swift bindings: ${OUTPUT_DIR}/${PROJECT_NAME}.swift"
echo ""
echo "🎯 Supported platforms:"
echo "  • iOS device (arm64)"
echo "  • iOS Simulator (arm64)"
echo "  • macOS (arm64 + x86_64)"
echo ""
echo "To use in your Xcode project:"
echo "1. Drag ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework into your project"
echo "2. Add ${OUTPUT_DIR}/${PROJECT_NAME}.swift to your project"
echo "3. Add '-lc++ -lresolv' to Other Linker Flags"