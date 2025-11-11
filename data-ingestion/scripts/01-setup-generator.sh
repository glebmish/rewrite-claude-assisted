#!/usr/bin/env bash

# Script: 01-setup-generator.sh
# Purpose: Clone and set up the rewrite-recipe-markdown-generator repository

# Load common utilities
COMMON_LIB="$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COMMON_LIB"

# Initialize script environment
init_script

# Version configuration - UPDATE THESE when bumping OpenRewrite versions
REWRITE_VERSION="${REWRITE_VERSION:-8.64.0}"
MODERNE_BOM_VERSION="${MODERNE_BOM_VERSION:-0.21.0}"
SPRING_QUARKUS_VERSION="${SPRING_QUARKUS_VERSION:-0.2.0}"

# Configuration with defaults
GENERATOR_REPO_URL="${GENERATOR_REPO_URL:-https://github.com/openrewrite/rewrite-recipe-markdown-generator.git}"

# Setup paths and Java
setup_generator_paths
setup_java

print_stage_header "Stage 1: Setup Generator Repository"

# Create workspace directory
mkdir -p "$GENERATOR_WORKSPACE"
cd "$GENERATOR_WORKSPACE"

GENERATOR_DIR="rewrite-recipe-markdown-generator"

# Check if generator already exists
if [ -d "$GENERATOR_DIR" ]; then
    log_success "Generator repository already exists at: $GENERATOR_DIR"
    log_info "To re-setup, remove the directory and run this script again"
else
    log_info "Cloning generator repository..."
    git clone "$GENERATOR_REPO_URL" "$GENERATOR_DIR"
    log_success "Generator cloned successfully"

    # Checkout to specific commit for reproducibility
    echo ""
    log_info "Checking out to commit 171ed7c4 for stable version..."
    cd "$GENERATOR_DIR"
    git checkout 171ed7c4
    cd -
    log_success "Checked out to commit 171ed7c4"
fi
cd "$GENERATOR_DIR"

# Verify Java version
echo ""
log_info "Verifying Java installation..."

verify_java_version "17" || exit 1

# Verify Gradle wrapper
if [ ! -f "./gradlew" ]; then
    log_error "Gradle wrapper not found in $GENERATOR_DIR"
    exit 1
fi

log_success "Gradle wrapper verified"

# Make gradlew executable
chmod +x ./gradlew

# Apply workarounds to build.gradle.kts for reproducibility
echo ""
log_info "Applying version pinning workarounds to build.gradle.kts..."

BUILD_FILE="build.gradle.kts"
if [ ! -f "$BUILD_FILE" ]; then
    log_error "build.gradle.kts not found"
    exit 1
fi

# Pin rewriteVersion to stable version for reproducibility
if grep -q 'val rewriteVersion = "latest.release"' "$BUILD_FILE"; then
    sed -i "s/val rewriteVersion = \"latest.release\"/val rewriteVersion = \"$REWRITE_VERSION\"/" "$BUILD_FILE"
    log_success "Pinned rewriteVersion to $REWRITE_VERSION"
else
    log_info "Note: rewriteVersion already modified or not found"
fi

# Pin moderne-recipe-bom version for reproducibility
if grep -q '"io.moderne.recipe:moderne-recipe-bom:$rewriteVersion"' "$BUILD_FILE"; then
    sed -i "s/\"io.moderne.recipe:moderne-recipe-bom:\$rewriteVersion\"/\"io.moderne.recipe:moderne-recipe-bom:$MODERNE_BOM_VERSION\"/" "$BUILD_FILE"
    log_success "Pinned moderne-recipe-bom to $MODERNE_BOM_VERSION"
else
    log_info "Note: moderne-recipe-bom already modified or not found"
fi

# Pin rewrite-spring-to-quarkus version for reproducibility
if grep -q '"org.openrewrite.recipe:rewrite-spring-to-quarkus:$rewriteVersion"' "$BUILD_FILE"; then
    sed -i "s/\"org.openrewrite.recipe:rewrite-spring-to-quarkus:\$rewriteVersion\"/\"org.openrewrite.recipe:rewrite-spring-to-quarkus:$SPRING_QUARKUS_VERSION\"/" "$BUILD_FILE"
    log_success "Pinned rewrite-spring-to-quarkus to $SPRING_QUARKUS_VERSION"
else
    log_info "Note: rewrite-spring-to-quarkus already modified or not found"
fi

# Apply custom metadata extraction task
echo ""
log_info "Configuring custom metadata extraction task..."

# Add apply statement at the end of build.gradle.kts (idempotent - check if already exists)
if ! grep -q 'apply.*extract-recipe-metadata.gradle.kts' "$BUILD_FILE"; then
    echo "" >> "$BUILD_FILE"
    echo "// Apply custom metadata extraction task" >> "$BUILD_FILE"
    echo "apply(from = \"../../scripts/extract-recipe-metadata.gradle.kts\")" >> "$BUILD_FILE"
    log_success "Applied custom metadata extraction task"
else
    log_info "Note: Metadata extraction task already applied"
fi

log_success "Build configuration workarounds complete"

echo ""
log_info "Generator location: $GENERATOR_DIR"
log_info "Java version: $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"
echo ""
log_info "NOTE: This setup NO LONGER uses rewrite-gradle-plugin"
log_info "      Instead, we use the markdown generator's approach:"
log_info "      - Isolated URLClassLoader with recipe JARs"
log_info "      - Environment.scanJar() for recipe discovery"
log_info "      - No dependency on plugin internals"

print_stage_footer "1" "02-generate-docs.sh"
