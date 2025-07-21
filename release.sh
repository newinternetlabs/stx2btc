#!/bin/bash
set -e

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo "Install with: brew install gh"
    exit 1
fi

# Check for version argument
if [ $# -eq 0 ]; then
    echo "Usage: ./release.sh <version>"
    echo "Example: ./release.sh v1.0.0"
    exit 1
fi

VERSION=$1

# Validate version format
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format vX.Y.Z"
    exit 1
fi

echo "🚀 Creating release $VERSION"

# Build XCFramework
echo "📦 Building XCFramework..."
./build-xcframework.sh

# Create zip
echo "🗜️ Creating zip archive..."
cd target/xcframework
zip -r stx2btc.xcframework.zip stx2btc.xcframework
cd ../..

# Calculate checksum
echo "🔐 Calculating checksum..."
CHECKSUM=$(swift package compute-checksum target/xcframework/stx2btc.xcframework.zip)
echo "Checksum: $CHECKSUM"

# Check if tag already exists
if git rev-parse $VERSION >/dev/null 2>&1; then
    echo "⚠️  Tag $VERSION already exists locally"
    # Check if tag exists on remote
    if git ls-remote --tags origin | grep -q "refs/tags/$VERSION"; then
        echo "✅ Tag already pushed to remote"
    else
        echo "📤 Pushing existing tag to remote..."
        git push origin $VERSION
    fi
else
    echo "🏷️ Creating git tag..."
    git tag -a $VERSION -m "Release $VERSION"
    echo "📤 Pushing tag to remote..."
    git push origin $VERSION
fi

# Create GitHub release
echo "📤 Creating GitHub release..."
gh release create $VERSION \
    target/xcframework/stx2btc.xcframework.zip \
    --title "Release $VERSION" \
    --notes "Release $VERSION

## New Features
- ✅ **macOS Support**: Full support for macOS (arm64 + x86_64)
- ✅ **Dual Products**: Separate \`stx2btcFFI\` (C layer) and \`stx2btc\` (Swift layer) products
- ✅ **Command-line SPM**: Fixed Swift Package Manager builds from command line

## Platform Support
- **iOS**: 13.0+ (device + simulator arm64)
- **macOS**: 14.0+ (arm64 + x86_64 universal)

## Installation

### Basic Usage
Add to your Package.swift dependencies:
\`\`\`swift
.package(url: \"https://github.com/newinternetlabs/stx2btc\", from: \"${VERSION#v}\")
\`\`\`

Then add to your target:
\`\`\`swift
.target(
    dependencies: [
        .product(name: \"stx2btc\", package: \"stx2btc\")
    ]
)
\`\`\`

### Advanced FFI Usage
For direct FFI access (e.g., for libraries building on stx2btc):
\`\`\`swift
.target(
    dependencies: [
        .product(name: \"stx2btcFFI\", package: \"stx2btc\"),
        .product(name: \"stx2btc\", package: \"stx2btc\")
    ]
)
\`\`\`

Checksum: $CHECKSUM"

# First, let's make sure we're up to date with remote
echo "📥 Pulling latest changes..."
git pull origin $(git rev-parse --abbrev-ref HEAD)

# Update Package.swift with the release URL
echo "📝 Updating Package.swift..."
DOWNLOAD_URL="https://github.com/newinternetlabs/stx2btc/releases/download/$VERSION/stx2btc.xcframework.zip"

cat > Package.swift << EOF
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
            url: "$DOWNLOAD_URL",
            checksum: "$CHECKSUM"
        ),
        .target(
            name: "stx2btc",
            dependencies: ["stx2btcFFI"],
            path: "Sources/stx2btc"
        ),
    ]
)
EOF

# Commit and push
echo "💾 Committing Package.swift update..."
git add Package.swift
git commit -m "Update Package.swift for release $VERSION"

# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "📤 Pushing to branch: $BRANCH"
git push origin $BRANCH

# Ensure everything is pushed before declaring success
echo "🔄 Verifying push..."
if git diff --quiet origin/$BRANCH HEAD; then
    echo "✅ All changes pushed successfully!"
else
    echo "⚠️  Warning: Some changes may not be pushed. Running push again..."
    git push origin $BRANCH
fi

echo ""
echo "✅ Release $VERSION created successfully!"
echo "📦 Package URL: https://github.com/newinternetlabs/stx2btc"
echo "⬇️ Download URL: $DOWNLOAD_URL"
echo ""
echo "To use in a Swift Package:"
echo "  Dependencies: https://github.com/newinternetlabs/stx2btc"
echo "  Version: $VERSION"