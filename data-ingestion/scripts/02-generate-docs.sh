#!/usr/bin/env bash
set -euo pipefail

# Script: 02-generate-docs.sh
# Purpose: Run the gradle task to generate all recipe markdown documentation

# Load common utilities
COMMON_LIB="$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COMMON_LIB"

# Initialize script environment
init_script

# Setup paths and Java
setup_generator_paths
setup_java

print_stage_header "Stage 2: Generate Recipe Documentation"

# Verify generator exists
verify_generator || exit 1

cd "$GENERATOR_DIR_FULL"

log_info "Starting documentation generation..."
log_info "This may take 10-15 minutes on first run (downloads ~1GB of JARs)"
log_info "Subsequent runs are faster (uses gradle cache)"
echo ""

# Run gradle with progress output
log_info "Running: ./gradlew run"
echo ""

# Execute gradle task
if ./gradlew run --no-daemon --console=plain; then
    echo ""
    log_success "Documentation generation completed successfully"
else
    echo ""
    log_error "Documentation generation failed"
    log_error "Check the output above for errors"
    exit 1
fi

# Verify output
GENERATOR_OUTPUT_DIR="$GENERATOR_OUTPUT_DIR"
RECIPES_PATH="$GENERATOR_OUTPUT_DIR/recipes"

if [ ! -d "$RECIPES_PATH" ]; then
    log_error "Expected output directory not found: $RECIPES_PATH"
    exit 1
fi

# Count generated files
RECIPE_COUNT=$(find "$RECIPES_PATH" -name "*.md" | wc -l)

if [ "$RECIPE_COUNT" -eq 0 ]; then
    log_error "No markdown files generated"
    exit 1
fi

echo ""
log_info "Output directory: $RECIPES_PATH"
log_info "Total markdown files: $RECIPE_COUNT"
log_info "Disk usage: $(du -sh "$GENERATOR_OUTPUT_DIR" | cut -f1)"

print_stage_footer "2" "02b-generate-structured-data.sh"
