#!/usr/bin/env bash
set -euo pipefail

# Script: 02b-generate-structured-data.sh
# Purpose: Generate structured recipe metadata JSON for embedding generation
#
# HOW IT WORKS:
# =============
# 1. Adds buildscript dependencies (Jackson, OpenRewrite) to build.gradle.kts
# 2. Applies the task script using apply(from="...")
# 3. Runs the extractRecipeMetadata Gradle task
# 4. Restores original build.gradle.kts using git checkout
#
# KEY INSIGHTS:
# - Buildscript dependencies make Jackson/OpenRewrite available for script compilation
# - The task MUST be applied to the project (not run as init script) to access
#   the project's full classpath, which includes ALL recipe dependencies:
#   - rewrite-java, rewrite-spring, rewrite-testing-frameworks, etc.
# - This way, Environment.builder().scanRuntimeClasspath() finds thousands of
#   recipes, not just the ~20 recipes in rewrite-core.

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

# Path to the task script
TASK_SCRIPT="$SCRIPT_DIR/recipe-metadata-task.gradle.kts"

if [ ! -f "$TASK_SCRIPT" ]; then
    echo "✗ Error: Task script not found: $TASK_SCRIPT"
    exit 1
fi

# Step 1: Temporarily modify build.gradle.kts to apply the task
echo "→ Preparing project with metadata extraction task..."
# The task script (recipe-metadata-task.gradle.kts) is self-contained with its own
# buildscript block, so we just need to apply it to the project.

# COMMENTED OUT FOR MANUAL TESTING - User will add this manually:
# {
#     echo ""
#     echo "// Temporarily added for metadata extraction"
#     echo "apply(from = \"$TASK_SCRIPT\")"
# } >> build.gradle.kts

echo "  → NOTE: Assuming build.gradle.kts already has the task applied"
echo "  → Manual addition required: apply(from = \"$TASK_SCRIPT\")"

# Step 2: Set up cleanup to restore original build.gradle.kts on script exit
# Uses git to restore - simpler and more reliable than manual backup

# COMMENTED OUT FOR MANUAL TESTING - User will restore manually:
# cleanup() {
#     git checkout -- build.gradle.kts 2>/dev/null || true
# }
# trap cleanup EXIT

# Step 3: Run the extractRecipeMetadata task
# Now it has access to ALL recipe dependencies via the project's classpath
if ./gradlew extractRecipeMetadata \
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

# Step 4: Restore original build.gradle.kts using git
# (The trap will also do this, but we do it explicitly for clarity)

# COMMENTED OUT FOR MANUAL TESTING - User will restore manually:
# git checkout -- build.gradle.kts
echo ""
echo "  → NOTE: Remember to manually remove the apply() line from build.gradle.kts when done"

# Verify output
if [ ! -f "$METADATA_FILE" ]; then
    echo "✗ Error: Expected output file not found: $METADATA_FILE"
    exit 1
fi

# Count recipes in JSON
RECIPE_COUNT=$(grep -c '"name"' "$METADATA_FILE" 2>/dev/null || echo "0")

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
