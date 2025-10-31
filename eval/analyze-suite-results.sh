#!/bin/bash

set -euo pipefail

ARTIFACTS_DIR="${1:-artifacts/}"
OUTPUT_DIR="suite-results"

# Colors for output
GREEN="✅"
RED="❌"
YELLOW="⚠️"

echo "🔍 Analyzing suite results from: $ARTIFACTS_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize arrays and counters
declare -A pr_runs
declare -A pr_urls
declare -A pr_data
total_runs=0
successful_runs=0
failed_runs=0
total_cost=0
total_duration=0

# Helper function to safely extract JSON values using jq
extract_json_value() {
    local file="$1"
    local path="$2"
    local default="${3:-}"

    if [ ! -f "$file" ]; then
        echo "$default"
        return
    fi

    # Extract value; if null or doesn't exist, use default
    local value=$(jq -r "if ($path) == null then \"$default\" else ($path) end" "$file" 2>/dev/null || echo "$default")
    echo "${value}"
}

# Helper function to safely add numbers
safe_add() {
    local a="${1:-0}"
    local b="${2:-0}"

    # Remove any non-numeric characters except dot and minus, take only first match
    a=$(echo "$a" | grep -oE '[0-9.]+' | head -1 || echo "0")
    b=$(echo "$b" | grep -oE '[0-9.]+' | head -1 || echo "0")

    if [ -z "$a" ] || [ "$a" = "" ]; then a=0; fi
    if [ -z "$b" ] || [ "$b" = "" ]; then b=0; fi

    echo "$a + $b" | bc -l 2>/dev/null || echo "0"
}

# Helper function to safely divide numbers
safe_divide() {
    local a="${1:-0}"
    local b="${2:-1}"
    local scale="${3:-2}"

    # Remove any non-numeric characters except dot and minus, take only first match
    a=$(echo "$a" | grep -oE '[0-9.]+' | head -1 || echo "0")
    b=$(echo "$b" | grep -oE '[0-9.]+' | head -1 || echo "1")

    if [ -z "$a" ] || [ "$a" = "" ]; then a=0; fi
    if [ -z "$b" ] || [ "$b" = "" ] || [ "$b" = "0" ]; then b=1; fi

    echo "scale=$scale; $a / $b" | bc -l 2>/dev/null || echo "0"
}

# Find all run-metadata directories
run_dirs=$(find "$ARTIFACTS_DIR" -type d -name "*-run-metadata" | sort)

if [ -z "$run_dirs" ]; then
    echo "❌ No run-metadata artifacts found!"
    exit 1
fi

echo "📦 Found $(echo "$run_dirs" | wc -l) run artifact(s)"

# Array to store all run data
declare -a all_runs

# Parse each run directory
for run_dir in $run_dirs; do
    echo "  Processing: $(basename "$run_dir")"
    
    # Initialize run data with defaults
    pr_num="unknown"
    pr_url=""
    status="unknown"
    duration="0"
    cost="0"
    
    # Parse workflow-metadata.json
    if [ -f "$run_dir/workflow-metadata.json" ]; then
        pr_url=$(extract_json_value "$run_dir/workflow-metadata.json" ".pr_url" "")

        if [ -n "$pr_url" ]; then
            pr_num=$(echo "$pr_url" | grep -oE '[0-9]+$' || echo "unknown")
        fi

        status=$(extract_json_value "$run_dir/workflow-metadata.json" ".status" "unknown")
        exit_code=$(extract_json_value "$run_dir/workflow-metadata.json" ".exit_code" "1")
        duration=$(extract_json_value "$run_dir/workflow-metadata.json" ".duration_seconds" "0")

        if [ "$exit_code" = "0" ]; then
            successful_runs=$((successful_runs + 1))
        else
            failed_runs=$((failed_runs + 1))
            status="failed"
        fi
    fi
    
    # Parse claude-cost-stats.json
    if [ -f "$run_dir/claude-cost-stats.json" ]; then
        cost=$(extract_json_value "$run_dir/claude-cost-stats.json" ".totals.costs.total_cost" "")
        # Fallback to non-totals path if totals not found
        if [ -z "$cost" ] || [ "$cost" = "null" ] || [ "$cost" = "" ]; then
            cost=$(extract_json_value "$run_dir/claude-cost-stats.json" ".costs.total_cost" "0")
        fi
    fi
    
    # Parse claude-usage-stats.json
    total_messages="0"
    tool_calls="0"
    successful_tools="0"
    tool_success_rate="0"
    if [ -f "$run_dir/claude-usage-stats.json" ]; then
        total_messages=$(extract_json_value "$run_dir/claude-usage-stats.json" ".metrics.total_messages" "0")
        tool_calls=$(extract_json_value "$run_dir/claude-usage-stats.json" ".metrics.tool_calls" "0")
        successful_tools=$(extract_json_value "$run_dir/claude-usage-stats.json" ".metrics.successful_tool_calls" "0")
        tool_success_rate=$(extract_json_value "$run_dir/claude-usage-stats.json" ".metrics.tool_success_rate" "0")
    fi
    
    # Parse subjective-evaluation.json
    score_truth="N/A"
    score_extract="N/A"
    score_mapping="N/A"
    score_valid="N/A"
    score_overall="N/A"
    if [ -f "$run_dir/subjective-evaluation.json" ]; then
        score_truth=$(extract_json_value "$run_dir/subjective-evaluation.json" ".detailed_metrics.truthfulness" "N/A")
        score_extract=$(extract_json_value "$run_dir/subjective-evaluation.json" ".detailed_metrics.intent_extraction_quality" "N/A")
        score_mapping=$(extract_json_value "$run_dir/subjective-evaluation.json" ".detailed_metrics.recipe_mapping_effectiveness" "N/A")
        score_valid=$(extract_json_value "$run_dir/subjective-evaluation.json" ".detailed_metrics.validation_correctness" "N/A")
        score_overall=$(extract_json_value "$run_dir/subjective-evaluation.json" ".scores.overall_session_effectiveness" "N/A")
    fi

    # Parse recipe-precision-analysis.json
    precision="N/A"
    recall="N/A"
    f1_score="N/A"
    is_perfect_match="N/A"
    unnecessary_changes="N/A"
    missing_changes="N/A"
    if [ -f "$run_dir/recipe-precision-analysis.json" ]; then
        precision=$(extract_json_value "$run_dir/recipe-precision-analysis.json" ".metrics.precision" "N/A")
        recall=$(extract_json_value "$run_dir/recipe-precision-analysis.json" ".metrics.recall" "N/A")
        f1_score=$(extract_json_value "$run_dir/recipe-precision-analysis.json" ".metrics.f1_score" "N/A")
        is_perfect_match=$(extract_json_value "$run_dir/recipe-precision-analysis.json" ".metrics.is_perfect_match" "N/A")
        unnecessary_changes=$(extract_json_value "$run_dir/recipe-precision-analysis.json" ".metrics.false_positives_unnecessary" "N/A")
        missing_changes=$(extract_json_value "$run_dir/recipe-precision-analysis.json" ".metrics.false_negatives_missing" "N/A")
    fi
    
    total_runs=$((total_runs + 1))
    total_cost=$(safe_add "$total_cost" "$cost")
    total_duration=$(safe_add "$total_duration" "$duration")
    
    # Track runs per PR (only if pr_num is valid)
    if [ "$pr_num" != "unknown" ] && [ -n "$pr_num" ]; then
        if [ -z "${pr_runs[$pr_num]:-}" ]; then
            pr_runs[$pr_num]=0
            pr_urls[$pr_num]="$pr_url"
        fi
        pr_runs[$pr_num]=$((pr_runs[$pr_num] + 1))
        run_number=${pr_runs[$pr_num]}
    else
        run_number=$total_runs
    fi
    
    # Calculate duration in minutes
    duration_min=$(safe_divide "$duration" "60" "1")

    # Store run data
    all_runs+=("$pr_num|$pr_url|$run_number|$status|$duration|$duration_min|$cost|$score_truth|$score_extract|$score_mapping|$score_valid|$score_overall|$total_messages|$tool_calls|$successful_tools|$tool_success_rate|$unnecessary_changes|$missing_changes|$precision|$recall|$f1_score|$is_perfect_match")
done

# Calculate suite-level metrics
success_rate=0
if [ $total_runs -gt 0 ]; then
    success_numerator=$((successful_runs * 100))
    success_rate=$(safe_divide "$success_numerator" "$total_runs" "2")
fi
total_duration_min=$(safe_divide "$total_duration" "60" "1")
avg_duration_per_run=$(safe_divide "$total_duration_min" "$total_runs" "1")
avg_cost_per_run=$(safe_divide "$total_cost" "$total_runs" "2")

# Count unique PRs
unique_prs=0
if [ -n "${!pr_runs[*]}" ]; then
    unique_prs=${#pr_runs[@]}
fi

# Generate Markdown Summary
summary_file="$OUTPUT_DIR/summary.md"
{
    echo "# 📊 Suite Evaluation Results"
    echo ""
    echo "**Execution Date:** $(date -u +%Y-%m-%d\ %H:%M:%S) UTC"
    echo ""
    echo "## Suite Overview"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Total PRs | $unique_prs |"
    echo "| Total Runs | $total_runs |"
    echo "| Successful | $successful_runs $GREEN |"
    echo "| Failed | $failed_runs $([ $failed_runs -gt 0 ] && echo "$RED" || echo "") |"
    echo "| Success Rate | ${success_rate}% |"
    echo "| Total Cost | \$$(printf '%.2f' $total_cost) |"
    echo "| Total Duration | ${total_duration_min} minutes |"
    echo "| Avg Duration/Run | ${avg_duration_per_run} minutes |"
    echo "| Avg Cost/Run | \$${avg_cost_per_run} |"
    echo ""
    
    # PR Summary Table (only if we have valid PRs)
    if [ $unique_prs -gt 0 ]; then
        echo "## PR Summary"
        echo ""
        echo "| PR | Runs | Success | Avg Duration | Avg Cost | Avg Overall Score |"
        echo "|----|------|---------|--------------|----------|-------------------|"
        
        for pr in $(printf '%s\n' "${!pr_runs[@]}" | sort -n); do
            pr_total=${pr_runs[$pr]}
            pr_url=${pr_urls[$pr]:-""}
            pr_success=0
            pr_duration_sum=0
            pr_cost_sum=0
            pr_score_sum=0
            pr_score_count=0

            for run_data in "${all_runs[@]}"; do
                IFS='|' read -r run_pr run_pr_url run_num run_status run_dur run_dur_min run_cost run_truth run_extract run_mapping run_valid run_overall run_msg run_tools run_succ_tools run_tool_rate prec_unnecessary prec_missing prec_divergence prec_accuracy prec_f1 prec_perfect <<< "$run_data"

                if [ "$run_pr" = "$pr" ]; then
                    [ "$run_status" = "success" ] && pr_success=$((pr_success + 1))
                    pr_duration_sum=$(safe_add "$pr_duration_sum" "$run_dur_min")
                    pr_cost_sum=$(safe_add "$pr_cost_sum" "$run_cost")
                    
                    if [ "$run_overall" != "N/A" ]; then
                        score_num=$(echo "$run_overall" | grep -oE '[0-9]+' || echo "0")
                        if [ -n "$score_num" ] && [ "$score_num" != "0" ]; then
                            pr_score_sum=$(safe_add "$pr_score_sum" "$score_num")
                            pr_score_count=$((pr_score_count + 1))
                        fi
                    fi
                fi
            done
            
            avg_duration=$(safe_divide "$pr_duration_sum" "$pr_total" "1")
            avg_cost=$(safe_divide "$pr_cost_sum" "$pr_total" "2")
            avg_score="N/A"
            if [ $pr_score_count -gt 0 ]; then
                avg_score_val=$(safe_divide "$pr_score_sum" "$pr_score_count" "0")
                avg_score="${avg_score_val}%"
            fi
            
            status_icon=$GREEN
            [ $pr_success -lt $pr_total ] && status_icon=$YELLOW
            [ $pr_success -eq 0 ] && status_icon=$RED
            
            # Format PR link
            pr_link="[#$pr]($pr_url)"
            
            echo "| $pr_link | $pr_total | $pr_success/$pr_total $status_icon | ${avg_duration}m | \$${avg_cost} | $avg_score |"
        done
        
        echo ""
    fi
    
    echo "## Detailed Results"
    echo ""
    echo "| PR | Run | Status | Duration | Cost | Truth | Extract | Mapping | Valid | Overall | Msgs | Tools | Tool Success | Unnecessary | Missing | Precision | Recall | F1 | Perfect |"
    echo "|----|-----|--------|----------|------|-------|---------|---------|-------|---------|------|-------|--------------|-------------|---------|-----------|--------|----|---------|"

    for run_data in "${all_runs[@]}"; do
        IFS='|' read -r run_pr run_pr_url run_num run_status run_dur run_dur_min run_cost run_truth run_extract run_mapping run_valid run_overall run_msg run_tools run_succ_tools run_tool_rate prec_unnecessary prec_missing prec_precision prec_recall prec_f1 prec_perfect <<< "$run_data"
        
        status_icon=$GREEN
        [ "$run_status" != "success" ] && status_icon=$RED
        
        total_pr_runs=1
        if [ "$run_pr" != "unknown" ] && [ -n "${pr_runs[$run_pr]:-}" ]; then
            total_pr_runs=${pr_runs[$run_pr]}
        fi
        
        # Format PR link
        if [ -n "$run_pr_url" ]; then
            pr_link="[#$run_pr]($run_pr_url)"
        else
            pr_link="#$run_pr"
        fi

        # Format precision metrics
        formatted_precision="$prec_precision"
        if [ "$prec_precision" != "N/A" ]; then
            formatted_precision=$(printf '%.2f' $prec_precision 2>/dev/null || echo "$prec_precision")
        fi

        formatted_recall="$prec_recall"
        if [ "$prec_recall" != "N/A" ]; then
            formatted_recall=$(printf '%.2f' $prec_recall 2>/dev/null || echo "$prec_recall")
        fi

        formatted_f1="$prec_f1"
        if [ "$prec_f1" != "N/A" ]; then
            formatted_f1=$(printf '%.2f' $prec_f1 2>/dev/null || echo "$prec_f1")
        fi

        perfect_icon="$prec_perfect"
        if [ "$prec_perfect" = "true" ]; then
            perfect_icon="$GREEN"
        elif [ "$prec_perfect" = "false" ]; then
            perfect_icon="$RED"
        fi

        # Format tool success rate
        formatted_tool_rate="$run_tool_rate"
        if [ "$run_tool_rate" != "0" ] && [ "$run_tool_rate" != "N/A" ]; then
            formatted_tool_rate=$(printf '%.2f' $run_tool_rate 2>/dev/null || echo "$run_tool_rate")
        fi

        echo "| $pr_link | $run_num/$total_pr_runs | $status_icon | ${run_dur_min}m | \$$(printf '%.2f' $run_cost 2>/dev/null || echo "$run_cost") | $run_truth | $run_extract | $run_mapping | $run_valid | $run_overall | $run_msg | $run_tools | ${run_succ_tools}/${run_tools} (${formatted_tool_rate}) | $prec_unnecessary | $prec_missing | $formatted_precision | $formatted_recall | $formatted_f1 | $perfect_icon |"
    done
    
} > "$summary_file"

# Output to GitHub Step Summary
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    cat "$summary_file" >> "$GITHUB_STEP_SUMMARY"
fi

# Generate JSON output
json_file="$OUTPUT_DIR/suite-results.json"
{
    echo "{"
    echo "  \"suite_metadata\": {"
    echo "    \"execution_date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "    \"total_prs\": $unique_prs,"
    echo "    \"total_runs\": $total_runs,"
    echo "    \"successful_runs\": $successful_runs,"
    echo "    \"failed_runs\": $failed_runs,"
    echo "    \"success_rate\": $success_rate,"
    echo "    \"total_cost\": $total_cost,"
    echo "    \"total_duration_seconds\": $total_duration,"
    echo "    \"total_duration_minutes\": $total_duration_min"
    echo "  },"
    echo "  \"runs\": ["
    
    first=true
    for run_data in "${all_runs[@]}"; do
        IFS='|' read -r run_pr run_pr_url run_num run_status run_dur run_dur_min run_cost run_truth run_extract run_mapping run_valid run_overall run_msg run_tools run_succ_tools run_tool_rate unnecessary_changes missing_changes precision recall f1_score is_perfect_match <<< "$run_data"

        [ "$first" = false ] && echo "    ,"
        first=false

        echo "    {"
        echo "      \"pr_number\": \"$run_pr\","
        echo "      \"pr_url\": \"$run_pr_url\","
        echo "      \"run_number\": $run_num,"
        echo "      \"status\": \"$run_status\","
        echo "      \"duration_seconds\": $run_dur,"
        echo "      \"duration_minutes\": $run_dur_min,"
        echo "      \"cost\": $run_cost,"
        echo "      \"scores\": {"
        echo "        \"truthfulness\": \"$run_truth\","
        echo "        \"extraction_quality\": \"$run_extract\","
        echo "        \"mapping_effectiveness\": \"$run_mapping\","
        echo "        \"validation_correctness\": \"$run_valid\","
        echo "        \"overall\": \"$run_overall\""
        echo "      },"
        echo "      \"tool_metrics\": {"
        echo "        \"total_messages\": $run_msg,"
        echo "        \"tool_calls\": $run_tools,"
        echo "        \"successful_tool_calls\": $run_succ_tools,"
        echo "        \"tool_success_rate\": $run_tool_rate"
        echo "      },"
        echo "      \"precision_metrics\": {"
        echo "        \"false_positives_unnecessary\": \"$unnecessary_changes\","
        echo "        \"false_negatives_missing\": \"$missing_changes\","
        echo "        \"precision\": \"$precision\","
        echo "        \"recall\": \"$recall\","
        echo "        \"f1_score\": \"$f1_score\","
        echo "        \"is_perfect_match\": \"$is_perfect_match\""
        echo "      }"
        echo -n "    }"
    done
    
    echo ""
    echo "  ]"
    echo "}"
} > "$json_file"

echo ""
echo "✅ Analysis complete!"
echo "   📄 Summary: $summary_file"
echo "   📊 JSON: $json_file"
echo ""
echo "Suite Results:"
echo "  • Total Runs: $total_runs"
echo "  • Success Rate: ${success_rate}%"
echo "  • Total Cost: \$$(printf '%.2f' $total_cost)"
echo "  • Total Duration: ${total_duration_min} minutes"
