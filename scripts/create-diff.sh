#!/bin/bash

# Create Diff Script
# Generates a git diff between two branches in a repository
# Usage: create-diff.sh <repo-path> <recommended-recipe-branch> <pr-branch> <output-file>

set -euo pipefail

# Function to show usage
usage() {
    echo "Usage: $0 <repo-path> <recommended-recipe-branch> <pr-branch> <output-file>"
    echo ""
    echo "Arguments:"
    echo "  repo-path                   Path to the git repository"
    echo "  recommended-recipe-branch   Branch with recommended recipe changes"
    echo "  pr-branch                   Original PR branch to compare against"
    echo "  output-file                 Path where the diff output will be written"
    echo ""
    echo "Example:"
    echo "  $0 .workspace/my-repo main pr-123 result/recommended-recipe-to-pr.diff"
    echo ""
    echo "This generates a diff showing differences from recommended-recipe-branch to pr-branch"
    exit 1
}

# Check argument count
if [[ $# -ne 4 ]]; then
    echo "Error: Expected 4 arguments, got $#"
    usage
fi

REPO_PATH="$1"
RECIPE_BRANCH="$2"
PR_BRANCH="$3"
OUTPUT_FILE="$4"

# Validate repository path exists
if [[ ! -d "$REPO_PATH" ]]; then
    echo "Error: Repository path does not exist: $REPO_PATH"
    exit 1
fi

# Validate it's a git repository
if [[ ! -d "$REPO_PATH/.git" ]]; then
    echo "Error: Not a git repository: $REPO_PATH"
    exit 1
fi

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ ! -d "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
    echo "Created output directory: $OUTPUT_DIR"
fi

# Change to repository directory
cd "$REPO_PATH"
echo "Working in repository: $(pwd)"

# Validate recommended recipe branch exists
if ! git rev-parse --verify "$RECIPE_BRANCH" >/dev/null 2>&1; then
    echo "Error: Recommended recipe branch does not exist: $RECIPE_BRANCH"
    exit 1
fi

# Validate PR branch exists
if ! git rev-parse --verify "$PR_BRANCH" >/dev/null 2>&1; then
    echo "Error: PR branch does not exist: $PR_BRANCH"
    exit 1
fi

echo "Generating diff from '$RECIPE_BRANCH' to '$PR_BRANCH'"

# Generate the diff
# This shows what changes would need to be applied to RECIPE_BRANCH to reach PR_BRANCH
git diff "$RECIPE_BRANCH" "$PR_BRANCH" > "$OUTPUT_FILE"

# Validate output file was created
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "Error: Failed to create output file: $OUTPUT_FILE"
    exit 1
fi

# Check file size and report
FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")
echo "Diff generated successfully: $OUTPUT_FILE"
echo "File size: $FILE_SIZE bytes"

if [[ "$FILE_SIZE" -eq 0 ]]; then
    echo "Note: Empty diff - branches are identical"
else
    # Count added/removed lines
    ADDED=$(grep -c "^+" "$OUTPUT_FILE" || echo "0")
    REMOVED=$(grep -c "^-" "$OUTPUT_FILE" || echo "0")
    echo "Lines added: $ADDED, Lines removed: $REMOVED"
fi

echo "Success: Diff created at $OUTPUT_FILE"
