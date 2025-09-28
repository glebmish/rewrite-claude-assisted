#!/bin/bash

# PR Precision Analysis Wrapper
# Integrates Python PR diff analysis with bash suite analysis

set -euo pipefail

# Function to analyze PR precision for a given run
analyze_run_precision() {
    local original_pr_url="$1"
    local recipe_pr_url="$2"
    local run_number="$3"

    if [[ -z "$original_pr_url" || -z "$recipe_pr_url" ]]; then
        echo "    Warning: Missing PR URLs for precision analysis (run $run_number)"
        return 1
    fi

    echo "    Analyzing PR precision for run $run_number..."
    echo "      Original PR: $original_pr_url"
    echo "      Recipe PR: $recipe_pr_url"

    # Run Python analysis
    local analysis_result
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if ! analysis_result=$(python3 "$script_dir/analyze_pr_precision.py" "$original_pr_url" "$recipe_pr_url" 2>/dev/null); then
        echo "      Error: Failed to analyze PR precision"
        return 1
    fi

    # Parse JSON result
    local status precision recall f1_score accuracy
    local exact_matches missing_changes unnecessary_changes

    status=$(echo "$analysis_result" | jq -r '.status // "error"' 2>/dev/null || echo "error")

    if [[ "$status" != "success" ]]; then
        local error_msg=$(echo "$analysis_result" | jq -r '.error // "unknown error"' 2>/dev/null || echo "unknown error")
        echo "      Error: $error_msg"
        return 1
    fi

    # Extract metrics
    precision=$(echo "$analysis_result" | jq -r '.metrics.precision // 0' 2>/dev/null || echo "0")
    recall=$(echo "$analysis_result" | jq -r '.metrics.recall // 0' 2>/dev/null || echo "0")
    f1_score=$(echo "$analysis_result" | jq -r '.metrics.f1_score // 0' 2>/dev/null || echo "0")
    accuracy=$(echo "$analysis_result" | jq -r '.metrics.accuracy // 0' 2>/dev/null || echo "0")
    exact_matches=$(echo "$analysis_result" | jq -r '.metrics.exact_matches // 0' 2>/dev/null || echo "0")
    missing_changes=$(echo "$analysis_result" | jq -r '.metrics.missing_changes // 0' 2>/dev/null || echo "0")
    unnecessary_changes=$(echo "$analysis_result" | jq -r '.metrics.unnecessary_changes // 0' 2>/dev/null || echo "0")

    # Format percentages
    local precision_pct=$(echo "$precision * 100" | bc -l 2>/dev/null | cut -d'.' -f1 2>/dev/null || echo "0")
    local recall_pct=$(echo "$recall * 100" | bc -l 2>/dev/null | cut -d'.' -f1 2>/dev/null || echo "0")
    local f1_pct=$(echo "$f1_score * 100" | bc -l 2>/dev/null | cut -d'.' -f1 2>/dev/null || echo "0")
    local accuracy_pct=$(echo "$accuracy * 100" | bc -l 2>/dev/null | cut -d'.' -f1 2>/dev/null || echo "0")

    # Output formatted results
    echo "      Precision: ${precision_pct}% (${exact_matches} correct / $((exact_matches + unnecessary_changes)) total recipe changes)"
    echo "      Recall: ${recall_pct}% (${exact_matches} captured / $((exact_matches + missing_changes)) total original changes)"
    echo "      F1 Score: ${f1_pct}%"
    echo "      Accuracy: ${accuracy_pct}%"
    echo "      Changes: ${exact_matches} exact matches, ${missing_changes} missing, ${unnecessary_changes} unnecessary"
    echo ""

    # Return CSV metrics for aggregation: precision,recall,f1,accuracy,exact,missing,unnecessary
    echo "$precision,$recall,$f1_score,$accuracy,$exact_matches,$missing_changes,$unnecessary_changes"
}

# Function to find PR URLs from scratchpad or claude logs
extract_pr_urls_from_artifacts() {
    local artifact_dir="$1"
    local original_pr=""
    local recipe_pr=""

    # Try to find PR URLs in scratchpad files
    for scratchpad_file in "$artifact_dir"/../scratchpad-*/*.md; do
        if [[ -f "$scratchpad_file" ]]; then
            # Look for original PR URL (input)
            if [[ -z "$original_pr" ]]; then
                original_pr=$(grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' "$scratchpad_file" | head -1 || echo "")
            fi

            # Look for recipe PR URL (generated)
            if [[ -z "$recipe_pr" ]]; then
                recipe_pr=$(grep -oE 'Created PR.*https://github\.com/[^/]+/[^/]+/pull/[0-9]+' "$scratchpad_file" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 || echo "")
            fi
        fi
    done

    # Try claude logs if scratchpad didn't have the info
    if [[ -z "$recipe_pr" ]]; then
        for log_file in "$artifact_dir"/*.jsonl; do
            if [[ -f "$log_file" ]]; then
                # Look for PR creation in claude logs
                recipe_pr=$(grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' "$log_file" | tail -1 || echo "")
                if [[ -n "$recipe_pr" && "$recipe_pr" != "$original_pr" ]]; then
                    break
                fi
            fi
        done
    fi

    echo "$original_pr,$recipe_pr"
}

# Export functions for use by main script
export -f analyze_run_precision
export -f extract_pr_urls_from_artifacts