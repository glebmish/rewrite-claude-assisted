#!/usr/bin/env bash
set -euo pipefail

# Script: 01-setup-generator.sh
# Purpose: Clone and set up the rewrite-recipe-markdown-generator repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

GENERATOR_DIR="$GENERATOR_WORKSPACE/rewrite-recipe-markdown-generator"

# Check if generator already exists
if [ -d "$GENERATOR_DIR" ]; then
    echo "✓ Generator repository already exists at: $GENERATOR_DIR"
    echo "  To update, run: cd $GENERATOR_DIR && git pull"
else
    echo "→ Cloning generator repository..."
    git clone --depth 1 "$GENERATOR_REPO_URL" "$GENERATOR_DIR"
    echo "✓ Generator cloned successfully"
fi

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
cd "$GENERATOR_DIR"
if [ ! -f "./gradlew" ]; then
    echo "✗ Error: Gradle wrapper not found in $GENERATOR_DIR"
    exit 1
fi

echo "✓ Gradle wrapper verified"

# Make gradlew executable
chmod +x ./gradlew

echo ""
echo "========================================="
echo "✓ Stage 1 Complete"
echo "========================================="
echo "Generator location: $GENERATOR_DIR"
echo "Java version: $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"
echo ""
echo "Next step: Run 02-generate-docs.sh"
