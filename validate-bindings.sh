#!/bin/bash
set -e

# Script to validate that Swift bindings are in sync with Rust library

echo "🔍 Validating Swift bindings are in sync with Rust library..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Temporary directory for comparison
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Generate fresh bindings to temporary location
echo "📦 Generating fresh Swift bindings..."
cargo build-libs > /dev/null 2>&1

# We need to temporarily redirect the output to our temp directory
# Save the original bindings directory
if [ -d "bindings" ]; then
    mv bindings bindings.backup
fi

# Generate bindings (they'll go to ./bindings)
cargo swift-bindings > /dev/null 2>&1

# Move the generated bindings to our temp directory
mv bindings/stx2btc.swift "$TEMP_DIR/"

# Restore original bindings directory
if [ -d "bindings.backup" ]; then
    mv bindings.backup bindings
else
    rm -rf bindings
fi

# Compare with committed bindings
echo "🔍 Comparing with committed bindings..."

if [ ! -f "Sources/stx2btc/stx2btc.swift" ]; then
    echo -e "${RED}❌ No committed Swift bindings found at Sources/stx2btc/stx2btc.swift${NC}"
    echo "Run 'just sync-bindings' to generate and commit bindings"
    exit 1
fi

# Compare the Swift files
if ! diff -q "Sources/stx2btc/stx2btc.swift" "$TEMP_DIR/stx2btc.swift" > /dev/null; then
    echo -e "${RED}❌ Swift bindings are out of sync!${NC}"
    echo ""
    echo "The committed Swift bindings don't match the current Rust library."
    echo "This means the bindings were generated from a different version of the Rust code."
    echo ""
    echo "To fix this, run:"
    echo "  just sync-bindings"
    echo ""
    echo "This will automatically stage the updated bindings. Then commit:"
    echo "  git commit -m 'Update Swift bindings'"
    echo ""
    echo "Differences:"
    diff "Sources/stx2btc/stx2btc.swift" "$TEMP_DIR/stx2btc.swift" || true
    exit 1
fi

echo -e "${GREEN}✅ Swift bindings are in sync with Rust library!${NC}"
echo ""
echo "The committed Swift bindings match the current Rust library."
echo "It's safe to create a release or publish changes."