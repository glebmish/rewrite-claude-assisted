#!/bin/bash
set -euo pipefail

# Recipe Validation Script
#
# This script validates OpenRewrite recipes against a repository by:
# 1. Creating an isolated copy of the repository
# 2. Applying the recipe using OpenRewrite
# 3. Capturing the resulting diff
# 4. Cleaning up the isolated copy
#
# Usage:
#   validate-recipe.sh \
#     --repo-path .workspace/spring-petclinic \
#     --recipe-file .output/<session>/recipe.yaml \
#     --output-diff .output/<session>/recipe.diff \
#     --java-home 11

# Parse arguments
REPO_PATH=""
RECIPE_FILE=""
OUTPUT_DIFF=""
JAVA_HOME=""
DEBUG_MODE=false
GRADLE_OUTPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo-path)
            REPO_PATH="$2"
            shift 2
            ;;
        --recipe-file)
            RECIPE_FILE="$2"
            shift 2
            ;;
        --output-diff)
            OUTPUT_DIFF="$2"
            shift 2
            ;;
        --java-home)
            JAVA_HOME="$2"
            shift 2
            ;;
        --debug)
            DEBUG_MODE=true
            shift 1
            ;;
        --gradle-output)
            GRADLE_OUTPUT="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

# Validate required arguments
if [[ -z "$REPO_PATH" || -z "$RECIPE_FILE" || -z "$OUTPUT_DIFF" || -z "$JAVA_HOME" ]]; then
    echo "Error: Missing required arguments" >&2
    echo "Usage: $0 --repo-path PATH --recipe-file FILE --output-diff FILE --java-home JAVA_HOME" >&2
    exit 2
fi

# Validate inputs exist
if [[ ! -d "$REPO_PATH" ]]; then
    echo "Error: Repository path does not exist: $REPO_PATH" >&2
    exit 2
fi

if [[ ! -f "$RECIPE_FILE" ]]; then
    echo "Error: Recipe file does not exist: $RECIPE_FILE" >&2
    exit 2
fi

if [[ ! -d "$JAVA_HOME" ]]; then
    echo "Error: Java home directory does not exist: $JAVA_HOME" >&2
    exit 2
fi

# Extract recipe name from YAML using yq
RECIPE_NAME=$(yq eval '.name' "$RECIPE_FILE" | grep -v "null" | head -n 1)
if [[ -z "$RECIPE_NAME" || "$RECIPE_NAME" == "null" ]]; then
    echo "Error: Could not extract recipe name from $RECIPE_FILE" >&2
    echo "Make sure the YAML file has a 'name' field" >&2
    exit 2
fi

echo "Recipe name: $RECIPE_NAME"

# Save starting directory for cleanup
STARTING_DIR=$(pwd)

# Create isolated repository copy with PID for uniqueness
REPO_NAME=$(basename "$REPO_PATH")
ISOLATED_REPO="${REPO_PATH}-rewrite-$$"

echo "Creating isolated copy: $ISOLATED_REPO"
cp -a "$REPO_PATH" "$ISOLATED_REPO"

# Get absolute path to init script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/rewrite.gradle"

 # Convert to absolute path to ensure cleanup works regardless of cwd
ISOLATED_REPO=$(cd "$ISOLATED_REPO" && pwd)
cd "$ISOLATED_REPO"
# Reset git state
git reset --hard HEAD
rm -f .git/index.lock

# Cleanup function (called on exit via trap)
cleanup() {
    cd "$STARTING_DIR"
    if [[ -d "$ISOLATED_REPO" ]]; then
        echo "Cleaning up isolated repository: $ISOLATED_REPO"
        rm -rf "$ISOLATED_REPO"
    fi
}
trap cleanup EXIT

# Copy recipe YAML to isolated repo root
cp "$RECIPE_FILE" "$ISOLATED_REPO/rewrite.yml"

if [[ ! -f "$INIT_SCRIPT" ]]; then
    echo "Error: Init script not found at $INIT_SCRIPT" >&2
    exit 2
fi

# Execute OpenRewrite
echo "Executing OpenRewrite with recipe: $RECIPE_NAME"

# Build gradle command with optional debug flags
GRADLE_ARGS=(rewriteRun --init-script "$INIT_SCRIPT" -DrecipeName="$RECIPE_NAME")
if [[ "$DEBUG_MODE" == true ]]; then
    echo "Debug mode enabled"
    GRADLE_ARGS+=(--debug --stacktrace)
fi

# Execute gradle with optional output redirection
if [[ -n "$GRADLE_OUTPUT" ]]; then
    echo "Redirecting Gradle output to: $GRADLE_OUTPUT"
    if ! JAVA_HOME="$JAVA_HOME" ./gradlew "${GRADLE_ARGS[@]}" > "$GRADLE_OUTPUT" 2>&1; then
        echo "Error: OpenRewrite execution failed (see $GRADLE_OUTPUT for details)" >&2
        exit 1
    fi
else
    if ! JAVA_HOME="$JAVA_HOME" ./gradlew "${GRADLE_ARGS[@]}"; then
        echo "Error: OpenRewrite execution failed" >&2
        exit 1
    fi
fi

# Add local gitignore to exclude common gradle artifacts in diff
echo "Adding local gitignore for gradle artifacts"
mkdir -p "$ISOLATED_REPO/.git/info"
cat > "$ISOLATED_REPO/.git/info/exclude" << 'GITIGNORE_EOF'
# Gradle artifacts
.gradle/
**/gradle-wrapper.jar
gradle/
gradlew
gradlew.bat

# OpenRewrite artifacts
rewrite.yml

# Build outputs
**/build/
**/out/
**/target/
**/bin/
GITIGNORE_EOF


# Capture full git diff (no exclusions)
echo "Capturing diff to: $OUTPUT_DIFF"
git add .
git diff --cached > "$OUTPUT_DIFF"

echo "Validation complete. Diff saved to: $OUTPUT_DIFF"
exit 0
