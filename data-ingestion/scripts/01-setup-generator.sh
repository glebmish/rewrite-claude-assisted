#!/usr/bin/env bash
set -euo pipefail

# Script: 01-setup-generator.sh
# Purpose: Clone and set up the rewrite-recipe-markdown-generator repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Configuration with defaults
GENERATOR_REPO_URL="${GENERATOR_REPO_URL:-https://github.com/openrewrite/rewrite-recipe-markdown-generator.git}"
GENERATOR_WORKSPACE="${GENERATOR_WORKSPACE:-$PROJECT_DIR/workspace}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"

echo "========================================="
echo "Stage 1: Setup Generator Repository"
echo "========================================="

# Create workspace directory
mkdir -p "$GENERATOR_WORKSPACE"
cd "$GENERATOR_WORKSPACE"

GENERATOR_DIR="rewrite-recipe-markdown-generator"

# Check if generator already exists
if [ -d "$GENERATOR_DIR" ]; then
    echo "✓ Generator repository already exists at: $GENERATOR_DIR"
    echo "  To re-setup, remove the directory and run this script again"
else
    echo "→ Cloning generator repository..."
    git clone "$GENERATOR_REPO_URL" "$GENERATOR_DIR"
    echo "✓ Generator cloned successfully"

    # Checkout to specific commit for reproducibility
    echo ""
    echo "→ Checking out to commit 171ed7c4 for stable version..."
    cd "$GENERATOR_DIR"
    git checkout 171ed7c4
    cd -
    echo "✓ Checked out to commit 171ed7c4"
fi
cd "$GENERATOR_DIR"

# Verify Java version
echo ""
echo "→ Verifying Java installation..."

if [ ! -d "$JAVA_HOME" ]; then
    echo "✗ Error: JAVA_HOME directory not found: $JAVA_HOME"
    echo "  Available Java installations:"
    update-alternatives --list java || true
    exit 1
fi

# Test Java version
if ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -q "version \"17"; then
    echo "✗ Error: Java 17 is required"
    echo "  Current JAVA_HOME: $JAVA_HOME"
    "$JAVA_HOME/bin/java" -version
    echo ""
    echo "  Available Java installations:"
    update-alternatives --list java || true
    exit 1
fi

echo "✓ Java 17 verified: $JAVA_HOME"

# Verify Gradle wrapper
if [ ! -f "./gradlew" ]; then
    echo "✗ Error: Gradle wrapper not found in $GENERATOR_DIR"
    exit 1
fi

echo "✓ Gradle wrapper verified"

# Make gradlew executable
chmod +x ./gradlew

# Apply workarounds to build.gradle.kts for reproducibility
echo ""
echo "→ Applying version pinning workarounds to build.gradle.kts..."

BUILD_FILE="build.gradle.kts"
if [ ! -f "$BUILD_FILE" ]; then
    echo "✗ Error: build.gradle.kts not found"
    exit 1
fi

# Pin rewriteVersion to stable version for reproducibility
if grep -q 'val rewriteVersion = "latest.release"' "$BUILD_FILE"; then
    sed -i 's/val rewriteVersion = "latest.release"/val rewriteVersion = "8.64.0"/' "$BUILD_FILE"
    echo "✓ Pinned rewriteVersion to 8.64.0"
else
    echo "  Note: rewriteVersion already modified or not found"
fi

# Pin moderne-recipe-bom version for reproducibility
if grep -q '"io.moderne.recipe:moderne-recipe-bom:$rewriteVersion"' "$BUILD_FILE"; then
    sed -i 's/"io.moderne.recipe:moderne-recipe-bom:$rewriteVersion"/"io.moderne.recipe:moderne-recipe-bom:0.21.0"/' "$BUILD_FILE"
    echo "✓ Pinned moderne-recipe-bom to 0.21.0"
else
    echo "  Note: moderne-recipe-bom already modified or not found"
fi

# Pin rewrite-spring-to-quarkus version for reproducibility
if grep -q '"org.openrewrite.recipe:rewrite-spring-to-quarkus:$rewriteVersion"' "$BUILD_FILE"; then
    sed -i 's/"org.openrewrite.recipe:rewrite-spring-to-quarkus:$rewriteVersion"/"org.openrewrite.recipe:rewrite-spring-to-quarkus:0.2.0"/' "$BUILD_FILE"
    echo "✓ Pinned rewrite-spring-to-quarkus to 0.2.0"
else
    echo "  Note: rewrite-spring-to-quarkus already modified or not found"
fi

# Apply rewrite-gradle-plugin for proper classloader isolation
echo ""
echo "→ Configuring rewrite-gradle-plugin for metadata extraction..."

# Add plugin to plugins block (idempotent)
if ! grep -q 'id("org.openrewrite.rewrite")' "$BUILD_FILE"; then
    sed -i '/id("org.owasp.dependencycheck")/a\    id("org.openrewrite.rewrite") version "6.28.2"' "$BUILD_FILE"
    echo "✓ Added rewrite-gradle-plugin to plugins"
else
    echo "  Note: rewrite-gradle-plugin already configured"
fi

# Add configuration after dependencies block (idempotent - add only once at end of file)
if ! grep -q 'configurations.getByName("rewrite").extendsFrom' "$BUILD_FILE"; then
    cat >> "$BUILD_FILE" << 'EOF'

// Configure rewrite plugin to use all recipe dependencies
afterEvaluate {
    configurations.getByName("rewrite").extendsFrom(configurations.getByName("recipe"))
}

// Apply custom metadata extraction task
apply(from = "../../scripts/extract-recipe-metadata.gradle.kts")
EOF
    echo "✓ Configured rewrite to use recipe dependencies"
    echo "✓ Applied custom metadata extraction task"
else
    echo "  Note: rewrite configuration already set up"
fi

echo "✓ Build configuration workarounds and plugin setup complete"

echo ""
echo "========================================="
echo "✓ Stage 1 Complete"
echo "========================================="
echo "Generator location: $GENERATOR_DIR"
echo "Java version: $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"
echo ""
echo "Next step: Run 02-generate-docs.sh"
