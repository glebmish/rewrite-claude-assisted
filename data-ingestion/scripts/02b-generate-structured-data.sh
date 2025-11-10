#!/usr/bin/env bash
set -euo pipefail

# Script: 02b-generate-structured-data.sh
# Purpose: Generate structured recipe metadata JSON for embedding generation

SCRIPT_DIR="$(pwd)/$(dirname "${BASH_SOURCE[0]}")"
PROJECT_DIR="$SCRIPT_DIR/.."

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Configuration with defaults
GENERATOR_WORKSPACE="${GENERATOR_WORKSPACE:-$PROJECT_DIR/workspace}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
GENERATOR_DIR="$GENERATOR_WORKSPACE/rewrite-recipe-markdown-generator"
OUTPUT_DIR="${GENERATOR_OUTPUT_DIR:-build/docs}"
METADATA_FILE="$OUTPUT_DIR/recipe-metadata.json"

echo "========================================="
echo "Stage 2b: Generate Structured Recipe Data"
echo "========================================="

# Verify generator exists
if [ ! -d "$GENERATOR_DIR" ]; then
    echo "✗ Error: Generator directory not found: $GENERATOR_DIR"
    echo "  Run 01-setup-generator.sh first"
    exit 1
fi

cd "$GENERATOR_DIR"

# Export JAVA_HOME for gradle
export JAVA_HOME

echo "→ Extracting recipe metadata..."
echo "  Output file: $METADATA_FILE"
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Path to the init script
INIT_SCRIPT="$SCRIPT_DIR/extract-recipe-metadata.gradle.kts"

if [ ! -f "$INIT_SCRIPT" ]; then
    echo "✗ Error: Init script not found: $INIT_SCRIPT"
    exit 1
fi

# Run gradle with the init script
if ./gradlew --init-script "$INIT_SCRIPT" extractRecipeMetadata \
    -PoutputFile="$METADATA_FILE" \
    --no-daemon \
    --console=plain; then
    echo ""
    echo "✓ Structured data generation completed successfully"
else
    echo ""
    echo "✗ Error: Structured data generation failed"
    echo "  Check the output above for errors"
    exit 1
fi

# Verify output
if [ ! -f "$METADATA_FILE" ]; then
    echo "✗ Error: Expected output file not found: $METADATA_FILE"
    exit 1
fi

# Count recipes in JSON
RECIPE_COUNT=$(grep -c '"name"' "$METADATA_FILE" || echo "0")

if [ "$RECIPE_COUNT" -eq 0 ]; then
    echo "✗ Error: No recipes found in metadata file"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Stage 2b Complete"
echo "========================================="
echo "Metadata file: $METADATA_FILE"
echo "Recipe count: $RECIPE_COUNT"
echo "File size: $(du -sh "$METADATA_FILE" | cut -f1)"
echo ""
echo "Next step: Run 03b-generate-embeddings.py"
