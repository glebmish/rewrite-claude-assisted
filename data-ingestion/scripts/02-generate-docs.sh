#!/usr/bin/env bash
set -euo pipefail

# Script: 02-generate-docs.sh
# Purpose: Run the gradle task to generate all recipe markdown documentation

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
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
GENERATOR_OUTPUT_DIR="${GENERATOR_OUTPUT_DIR:-build/docs}"

echo "========================================="
echo "Stage 2: Generate Recipe Documentation"
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

echo "→ Starting documentation generation..."
echo "  This may take 10-15 minutes on first run (downloads ~1GB of JARs)"
echo "  Subsequent runs are faster (uses gradle cache)"
echo ""

# Run gradle with progress output
echo "→ Running: ./gradlew run"
echo ""

# Execute gradle task
if ./gradlew run --no-daemon --console=plain; then
    echo ""
    echo "✓ Documentation generation completed successfully"
else
    echo ""
    echo "✗ Error: Documentation generation failed"
    echo "  Check the output above for errors"
    exit 1
fi

# Verify output
OUTPUT_PATH="$GENERATOR_OUTPUT_DIR"
RECIPES_PATH="$OUTPUT_PATH/recipes"

if [ ! -d "$RECIPES_PATH" ]; then
    echo "✗ Error: Expected output directory not found: $RECIPES_PATH"
    exit 1
fi

# Count generated files
RECIPE_COUNT=$(find "$RECIPES_PATH" -name "*.md" | wc -l)

if [ "$RECIPE_COUNT" -eq 0 ]; then
    echo "✗ Error: No markdown files generated"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Stage 2 Complete"
echo "========================================="
echo "Output directory: $RECIPES_PATH"
echo "Total markdown files: $RECIPE_COUNT"
echo "Disk usage: $(du -sh "$OUTPUT_PATH" | cut -f1)"
echo ""
echo "Next step: Run 03-ingest-docs.py"
