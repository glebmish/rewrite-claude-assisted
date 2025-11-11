#!/usr/bin/env bash
set -euo pipefail

# Script: 02b-generate-structured-data.sh
# Purpose: Generate structured recipe metadata JSON for embedding generation
#
# HOW IT WORKS:
# =============
# 1. Uses the markdown generator's approach (NO rewrite-gradle-plugin dependency)
# 2. Creates isolated URLClassLoader with all JARs from 'recipe' configuration
# 3. Uses Environment.scanJar() to discover recipes from each first-level JAR
# 4. Custom task extracts detailed metadata (name, description, options, etc.)
# 5. Discovers all available recipes without classloader conflicts
#
# KEY INSIGHTS:
# - Follows rewrite-recipe-markdown-generator's official approach
# - Isolated URLClassLoader prevents dependency conflicts
# - Uses public Environment.scanJar() API (stable, documented)
# - No dependency on rewrite-gradle-plugin internals
# - Guaranteed to find all recipes in the classpath

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

echo "→ Extracting recipe metadata using isolated classloader approach..."
echo "  Approach: Markdown generator's recipe discovery method"
echo "  Configuration: recipe (all OpenRewrite modules)"
echo "  Output file: $METADATA_FILE"
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run the extractRecipeMetadata task
# This task creates an isolated URLClassLoader and uses Environment.scanJar()
echo "→ Running extractRecipeMetadata task..."
if ./gradlew extractRecipeMetadata \
    --no-daemon \
    --console=plain; then
    echo ""
    echo "✓ Recipe metadata extraction completed successfully"
else
    echo ""
    echo "✗ Error: Recipe metadata extraction failed"
    echo "  Check the output above for errors"
    exit 1
fi

# Copy output from build directory to expected location
PLUGIN_OUTPUT="build/recipe-metadata.json"
if [ ! -f "$PLUGIN_OUTPUT" ]; then
    echo "✗ Error: Output file not found: $PLUGIN_OUTPUT"
    exit 1
fi

# If output dir is different from build/, copy the file
if [ "$OUTPUT_DIR" != "build/docs" ]; then
    echo "→ Copying output to: $METADATA_FILE"
    cp "$PLUGIN_OUTPUT" "$METADATA_FILE"
else
    # Just ensure it's in the right place
    if [ "$PLUGIN_OUTPUT" != "$METADATA_FILE" ]; then
        cp "$PLUGIN_OUTPUT" "$METADATA_FILE"
    fi
fi

# Verify output
if [ ! -f "$METADATA_FILE" ]; then
    echo "✗ Error: Expected output file not found: $METADATA_FILE"
    exit 1
fi

# Count recipes in JSON
RECIPE_COUNT=$(jq '. | length' "$METADATA_FILE" 2>/dev/null || echo "0")

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
echo "Next step: Run 03-ingest-docs.py"
