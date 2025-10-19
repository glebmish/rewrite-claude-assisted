#!/bin/bash

set -euo pipefail

# This script generates a GitHub Actions matrix from PR configurations
# Usage: generate-matrix.sh "pr_url1|runs1" "pr_url2|runs2" ...

echo "🔧 Generating execution matrix..."

# Build matrix from arguments
matrix_items=""
pr_summary=""
pr_count=0
pr_index=0  # ADD THIS

for config in "$@"; do
    IFS='|' read -ra parts <<< "$config"
    pr_url="${parts[0]}"
    runs="${parts[1]}"
    pr_num=$(echo "$pr_url" | grep -oE '[0-9]+$')
    
    pr_count=$((pr_count + 1))
    
    echo "  📋 [$pr_index] PR #$pr_num: $runs run(s)"  # CHANGE THIS
    
    # Add to summary
    if [ -n "$pr_summary" ]; then
        pr_summary="$pr_summary|"
    fi
    pr_summary="$pr_summary$pr_url:$pr_num:$runs"
    
    # Generate matrix entries for each run
    for run in $(seq 1 "$runs"); do
        if [ -n "$matrix_items" ]; then
            matrix_items="$matrix_items,"
        fi
        # ADD pr_index TO THE MATRIX ITEM
        matrix_items="$matrix_items{\"pr_url\":\"$pr_url\",\"pr_num\":\"$pr_num\",\"pr_index\":$pr_index,\"run\":$run,\"total_runs\":$runs}"
    done
    
    pr_index=$((pr_index + 1))  # ADD THIS
done

# Create final matrix JSON
matrix="{\"include\":[$matrix_items]}"

# Output to GitHub Actions
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "matrix=$matrix" >> "$GITHUB_OUTPUT"
    echo "pr_summary=$pr_summary" >> "$GITHUB_OUTPUT"
fi

# Also output to stdout for debugging
echo ""
echo "✅ Generated matrix for $pr_count PR configuration(s)"
echo "Matrix: $matrix"
echo "Summary: $pr_summary"
