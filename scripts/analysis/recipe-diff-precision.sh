#!/bin/bash
# Recipe Diff Precision Analysis
# Analyzes recommended-recipe-to-pr.diff to calculate recipe effectiveness
#
# The diff is from recipe-applied-branch TO original-PR-branch, meaning:
# - '-' lines: Recipe made changes that PR didn't have (UNNECESSARY/false positives)
# - '+' lines: PR has changes that recipe didn't make (MISSING/false negatives)
# - Empty diff: Perfect match!

set -euo pipefail

# Function to show usage
usage() {
    echo "Usage: $0 <diff-file> <output-json-file>"
    echo "  diff-file: Path to recommended-recipe-to-pr.diff"
    echo "  output-json-file: Path where JSON results will be saved"
    exit 1
}

# Check arguments
if [[ $# -ne 2 ]]; then
    usage
fi

DIFF_FILE="$1"
OUTPUT_FILE="$2"

if [[ ! -f "$DIFF_FILE" ]]; then
    echo "Error: Diff file not found: $DIFF_FILE"
    exit 1
fi

echo "Analyzing recipe precision from: $DIFF_FILE"

# Count actual code changes (exclude file headers '---' and '+++')
# Unnecessary: lines starting with '-' but not '---'
unnecessary=$(grep -c '^-[^-]' "$DIFF_FILE" 2>/dev/null || echo "0")
unnecessary=${unnecessary:-0}

# Missing: lines starting with '+' but not '+++'
missing=$(grep -c '^\+[^+]' "$DIFF_FILE" 2>/dev/null || echo "0")
missing=${missing:-0}

# Total divergence (ensure numeric values)
total_divergence=$(( ${unnecessary} + ${missing} ))

echo "  Unnecessary changes (false positives): $unnecessary"
echo "  Missing changes (false negatives): $missing"
echo "  Total divergence: $total_divergence"

# Calculate metrics
if [[ $total_divergence -eq 0 ]]; then
    # Perfect match!
    precision="1.0"
    recall="1.0"
    f1_score="1.0"
    accuracy="1.0"
    echo "  Result: Perfect match! Recipe output matches PR exactly."
else
    # Calculate precision, recall, and F1 score
    # Precision = changes_correct / (changes_correct + changes_unnecessary)
    # We approximate: if we have N missing and M unnecessary, then:
    # - Total attempted by recipe: (total_pr_changes - missing) + unnecessary
    # - Correct: (total_pr_changes - missing)
    # But we don't know total_pr_changes, so we use relative metrics:

    # Simplified approach: measure match rate
    # Precision: what fraction of recipe changes were correct (not unnecessary)
    # Recall: what fraction of PR changes were captured (not missing)

    if [[ $unnecessary -gt 0 ]]; then
        precision=$(echo "scale=4; 1 / (1 + $unnecessary / 10.0)" | bc -l)
    else
        precision="1.0"
    fi

    if [[ $missing -gt 0 ]]; then
        recall=$(echo "scale=4; 1 / (1 + $missing / 10.0)" | bc -l)
    else
        recall="1.0"
    fi

    # F1 Score: harmonic mean of precision and recall
    f1_score=$(echo "scale=4; 2 * $precision * $recall / ($precision + $recall)" | bc -l)

    # Accuracy: overall match quality (inverse of divergence rate)
    accuracy=$(echo "scale=4; 1 / (1 + $total_divergence / 20.0)" | bc -l)

    echo "  Precision: $precision"
    echo "  Recall: $recall"
    echo "  F1 Score: $f1_score"
    echo "  Accuracy: $accuracy"
fi

# Create output JSON
cat > "$OUTPUT_FILE" << EOF
{
  "diff_file": "$DIFF_FILE",
  "analysis_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "metrics": {
    "unnecessary_changes": $unnecessary,
    "missing_changes": $missing,
    "total_divergence": $total_divergence,
    "precision": $precision,
    "recall": $recall,
    "f1_score": $f1_score,
    "accuracy": $accuracy,
    "is_perfect_match": $([ $total_divergence -eq 0 ] && echo "true" || echo "false")
  },
  "interpretation": {
    "unnecessary_changes_meaning": "Recipe made changes that the original PR did not have (false positives)",
    "missing_changes_meaning": "PR has changes that the recipe failed to implement (false negatives)",
    "perfect_match": $([ $total_divergence -eq 0 ] && echo "true" || echo "false")
  }
}
EOF

echo "Recipe precision analysis saved to: $OUTPUT_FILE"
