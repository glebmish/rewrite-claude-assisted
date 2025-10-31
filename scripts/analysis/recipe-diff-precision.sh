#!/bin/bash
# Recipe Diff Precision Analysis
# Analyzes recipe effectiveness by comparing its output against an original PR diff.

set -euo pipefail

# Function to show usage
usage() {
    echo "Usage: $0 <pr-diff> <recipe-vs-pr-diff> <output-json-file>"
    echo "  pr-diff:              Diff of the original PR against main"
    echo "  recipe-vs-pr-diff:    Diff from the recipe output to the PR (shows recipe errors)"
    echo "  output-json-file:     Path where JSON results will be saved"
    exit 1
}

# Check arguments
if [[ $# -ne 3 ]]; then
    usage
fi

pr_DIFF="$1"
RECIPE_VS_PR_DIFF="$2"
OUTPUT_FILE="$3"

if [[ ! -f "$pr_DIFF" ]]; then
    echo "Error: PR diff file not found: $pr_DIFF"
    exit 1
fi

if [[ ! -f "$RECIPE_VS_PR_DIFF" ]]; then
    echo "Error: Recipe vs PR diff file not found: $RECIPE_VS_PR_DIFF"
    exit 1
fi

echo "Analyzing recipe precision..."

# 1. Calculate |G|, the total number of changes in the PR diff
additions_g=$(grep -c '^\+[^+]' "$pr_DIFF" 2>/dev/null || true)
removals_g=$(grep -c '^-[^-]' "$pr_DIFF" 2>/dev/null || true)
total_expected_changes=$((additions_g + removals_g))

# 2. Calculate FP and FN from the diff between the recipe and the PR
# The diff is FROM recipe TO pr, so:
# - Lines to add (+) are changes the recipe MISSED (FN)
# - Lines to remove (-) are changes the recipe made UNNECESSARILY (FP)
fp=$(grep -c '^-[^-]' "$RECIPE_VS_PR_DIFF" 2>/dev/null || true)
fn=$(grep -c '^\+[^+]' "$RECIPE_VS_PR_DIFF" 2>/dev/null || true)

# 3. Calculate TP = |G| - FN
tp=$((total_expected_changes - fn))

if [[ $tp -lt 0 ]]; then
    echo "Error: Calculated True Positives ($tp) is negative. Check your diff files."
    exit 1
fi

echo "  Total original PR changes: $total_expected_changes"
echo "  True positives (correctly made by recipe): $tp"
echo "  False positives (unnecessary changes by recipe): $fp"
echo "  False negatives (changes missed by recipe): $fn"

# 4. Calculate standard metrics
is_perfect_match=false
if [[ $fp -eq 0 && $fn -eq 0 ]]; then
    is_perfect_match=true
    precision="1.0"
    recall="1.0"
    f1_score="1.0"
else
    # Precision = TP / (TP + FP)
    precision_denominator=$((tp + fp))
    if [[ $precision_denominator -eq 0 ]]; then
        # If TP=0 and FP=0, the recipe correctly did nothing. Precision is perfect.
        precision="1.0"
    else
        precision=$(echo "scale=4; $tp / $precision_denominator" | bc -l)
    fi

    # Recall = TP / (TP + FN) = TP / |G|
    recall_denominator=$total_expected_changes
    if [[ $recall_denominator -eq 0 ]]; then
        # If |G|=0, no changes were required. Recall is perfect.
        recall="1.0"
    else
        recall=$(echo "scale=4; $tp / $recall_denominator" | bc -l)
    fi

    # F1 Score = 2 * (Precision * Recall) / (Precision + Recall)
    f1_denominator=$(echo "$precision + $recall" | bc -l)
    if (( $(echo "$f1_denominator == 0" | bc -l) )); then
        f1_score="0.0"
    else
        f1_score=$(echo "scale=4; 2 * $precision * $recall / $f1_denominator" | bc -l)
    fi
fi

# For clarity, total_divergence is still useful
total_divergence=$((fp + fn))

echo "  Precision: $precision"
echo "  Recall: $recall"
echo "  F1 Score: $f1_score"

# Create output JSON using jq
jq -n \
  --arg pr_diff "$pr_DIFF" \
  --arg recipe_vs_pr_diff "$RECIPE_VS_PR_DIFF" \
  --arg analysis_timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --argjson total_expected_changes "$total_expected_changes" \
  --argjson true_positives "$tp" \
  --argjson false_positives "$fp" \
  --argjson false_negatives "$fn" \
  --argjson total_divergence "$total_divergence" \
  --argjson precision "$precision" \
  --argjson recall "$recall" \
  --argjson f1_score "$f1_score" \
  --argjson is_perfect_match "$is_perfect_match" \
'{
  "diff_files": {
    "pr": $pr_diff,
    "recipe_vs_pr": $recipe_vs_pr_diff
  },
  "analysis_timestamp": $analysis_timestamp,
  "metrics": {
    "total_expected_changes": $total_expected_changes,
    "true_positives": $true_positives,
    "false_positives_unnecessary": $false_positives,
    "false_negatives_missing": $false_negatives,
    "total_divergence": $total_divergence,
    "precision": $precision,
    "recall": $recall,
    "f1_score": $f1_score,
    "is_perfect_match": $is_perfect_match
  },
  "interpretation": {
    "false_positives_unnecessary_meaning": "Recipe made changes that the original PR did not have.",
    "false_negatives_missing_meaning": "PR has changes that the recipe failed to implement.",
    "perfect_match": $is_perfect_match
  }
}' > "$OUTPUT_FILE"

echo "Recipe precision analysis saved to: $OUTPUT_FILE"
