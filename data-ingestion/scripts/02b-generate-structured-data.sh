#!/usr/bin/env bash

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

# Load common utilities
COMMON_LIB="$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COMMON_LIB"

# Initialize script environment
init_script

# Setup paths and Java
setup_generator_paths
setup_java

OUTPUT_DIR="${GENERATOR_OUTPUT_DIR:-build/docs}"
METADATA_FILE="$OUTPUT_DIR/recipe-metadata.json"

print_stage_header "Stage 2b: Generate Structured Recipe Data"

# Verify generator exists
verify_generator || exit 1

cd "$GENERATOR_DIR"

log_info "Extracting recipe metadata using isolated classloader approach..."
log_info "Approach: Markdown generator's recipe discovery method"
log_info "Configuration: recipe (all OpenRewrite modules)"
log_info "Output file: $METADATA_FILE"
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run the extractRecipeMetadata task
# This task creates an isolated URLClassLoader and uses Environment.scanJar()
log_info "Running extractRecipeMetadata task..."
if ./gradlew extractRecipeMetadata \
    --no-daemon \
    --console=plain; then
    echo ""
    log_success "Recipe metadata extraction completed successfully"
else
    echo ""
    log_error "Recipe metadata extraction failed"
    log_error "Check the output above for errors"
    exit 1
fi

# Copy output from build directory to expected location
PLUGIN_OUTPUT="build/recipe-metadata.json"
if [ ! -f "$PLUGIN_OUTPUT" ]; then
    log_error "Output file not found: $PLUGIN_OUTPUT"
    exit 1
fi

# If output dir is different from build/, copy the file
if [ "$OUTPUT_DIR" != "build/docs" ]; then
    log_info "Copying output to: $METADATA_FILE"
    cp "$PLUGIN_OUTPUT" "$METADATA_FILE"
else
    # Just ensure it's in the right place
    if [ "$PLUGIN_OUTPUT" != "$METADATA_FILE" ]; then
        cp "$PLUGIN_OUTPUT" "$METADATA_FILE"
    fi
fi

# Verify output
if [ ! -f "$METADATA_FILE" ]; then
    log_error "Expected output file not found: $METADATA_FILE"
    exit 1
fi

# Count recipes in JSON
RECIPE_COUNT=$(jq '. | length' "$METADATA_FILE" 2>/dev/null || echo "0")

if [ "$RECIPE_COUNT" -eq 0 ]; then
    log_error "No recipes found in metadata file"
    exit 1
fi

echo ""
log_info "Metadata file: $METADATA_FILE"
log_info "Recipe count: $RECIPE_COUNT"
log_info "File size: $(du -sh "$METADATA_FILE" | cut -f1)"

print_stage_footer "2b" "03-ingest-docs.py"
