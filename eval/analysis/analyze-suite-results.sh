#!/bin/bash
set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source analysis modules
source "$SCRIPT_DIR/analyze-claude-logs.sh"
source "$SCRIPT_DIR/analyze-scratchpads.sh"
source "$SCRIPT_DIR/analyze-pr-precision.sh"

# Default values
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"
OUTPUT_DIR="suite-results"
SUITE_REPORT="$OUTPUT_DIR/suite-summary.txt"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize report
log "Starting Simple Suite Eval Analysis"
echo "Simple Suite Eval - Final Summary" > "$SUITE_REPORT"
echo "Generated: $(date)" >> "$SUITE_REPORT"
echo "========================================" >> "$SUITE_REPORT"
echo "" >> "$SUITE_REPORT"

# Analyze all artifacts regardless of PR summary (since pr_summary might be empty)
echo "Analyzing all artifacts found..." >> "$SUITE_REPORT"

# Count and analyze all artifacts
total_claude_logs=0
total_scratchpad=0
actual_runs=0

# Aggregated metrics
total_messages=0
total_tool_calls=0
total_successful_tools=0
total_failed_tools=0
successful_workflows=0
failed_workflows=0

# PR precision metrics
total_precision=0
total_recall=0
total_f1=0
total_accuracy=0
total_exact_matches=0
total_missing_changes=0
total_unnecessary_changes=0
precision_analyses=0

echo "  Detailed Analysis:" >> "$SUITE_REPORT"
echo "" >> "$SUITE_REPORT"

# Process all claude-log artifacts
for artifact_dir in "$ARTIFACTS_DIR"/claude-log-*/; do
  if [ -d "$artifact_dir" ]; then
    actual_runs=$((actual_runs + 1))
    run_number=$(basename "$artifact_dir" | sed 's/claude-log-//')

    # Count files in this run's artifacts
    claude_log_count=$(find "$artifact_dir" -type f 2>/dev/null | wc -l)
    total_claude_logs=$((total_claude_logs + claude_log_count))

    echo "  Run $run_number (claude logs): $claude_log_count files" >> "$SUITE_REPORT"

    # Analyze each JSONL file in detail
    for log_file in "$artifact_dir"/*.jsonl; do
      if [[ -f "$log_file" ]]; then
        echo "    Analyzing $(basename "$log_file"):" >> "$SUITE_REPORT"

        # Capture analysis output and metrics
        analysis_output=$(analyze_claude_log "$log_file" "$run_number" 2>&1)

        # Extract the last line which contains CSV metrics
        metrics_line=$(echo "$analysis_output" | tail -n 1)
        display_output=$(echo "$analysis_output" | head -n -1)

        # Add analysis to report
        echo "$display_output" >> "$SUITE_REPORT"

        # Parse metrics for aggregation
        if [[ "$metrics_line" =~ ^[0-9] ]]; then
          IFS=',' read -r messages tools succ_tools fail_tools duration status <<< "$metrics_line"
          total_messages=$((total_messages + messages))
          total_tool_calls=$((total_tool_calls + tools))
          total_successful_tools=$((total_successful_tools + succ_tools))
          total_failed_tools=$((total_failed_tools + fail_tools))

          if [[ "$status" == "success" ]]; then
            successful_workflows=$((successful_workflows + 1))
          elif [[ "$status" == "failure" ]]; then
            failed_workflows=$((failed_workflows + 1))
          fi
        fi
      fi
    done

    # Add PR precision analysis for this run
    echo "    PR Precision Analysis:" >> "$SUITE_REPORT"
    pr_urls=$(extract_pr_urls_from_artifacts "$artifact_dir")
    IFS=',' read -r original_pr recipe_pr <<< "$pr_urls"

    if [[ -n "$original_pr" && -n "$recipe_pr" ]]; then
      precision_result=$(analyze_run_precision "$original_pr" "$recipe_pr" "$run_number" 2>&1)

      # Extract metrics line (last line) and display output (all but last line)
      precision_metrics=$(echo "$precision_result" | tail -n 1)
      precision_display=$(echo "$precision_result" | head -n -1)

      # Add to report
      echo "$precision_display" >> "$SUITE_REPORT"

      # Parse and aggregate precision metrics
      if [[ "$precision_metrics" =~ ^[0-9] ]]; then
        IFS=',' read -r precision recall f1 accuracy exact missing unnecessary <<< "$precision_metrics"
        total_precision=$(echo "$total_precision + $precision" | bc -l)
        total_recall=$(echo "$total_recall + $recall" | bc -l)
        total_f1=$(echo "$total_f1 + $f1" | bc -l)
        total_accuracy=$(echo "$total_accuracy + $accuracy" | bc -l)
        total_exact_matches=$((total_exact_matches + exact))
        total_missing_changes=$((total_missing_changes + missing))
        total_unnecessary_changes=$((total_unnecessary_changes + unnecessary))
        precision_analyses=$((precision_analyses + 1))
      fi
    else
      echo "    No PR URLs found for precision analysis" >> "$SUITE_REPORT"
    fi

    echo "" >> "$SUITE_REPORT"
  fi
done

# Scratchpad analysis metrics
total_scratchpad_lines=0
total_phases_completed=0
total_phases_failed=0
total_scratchpad_errors=0
total_scratchpad_warnings=0
completed_workflows=0
partial_workflows=0
failed_scratchpad_workflows=0

# Process all scratchpad artifacts
scratchpad_runs=0
for artifact_dir in "$ARTIFACTS_DIR"/scratchpad-*/; do
  if [ -d "$artifact_dir" ]; then
    scratchpad_runs=$((scratchpad_runs + 1))
    run_number=$(basename "$artifact_dir" | sed 's/scratchpad-//')

    # Count files in this run's artifacts
    scratchpad_count=$(find "$artifact_dir" -type f 2>/dev/null | wc -l)
    total_scratchpad=$((total_scratchpad + scratchpad_count))

    echo "  Run $run_number (scratchpad): $scratchpad_count files" >> "$SUITE_REPORT"

    # Analyze each scratchpad file in detail
    for scratchpad_file in "$artifact_dir"/*.md; do
      if [[ -f "$scratchpad_file" ]]; then
        echo "    Analyzing $(basename "$scratchpad_file"):" >> "$SUITE_REPORT"

        # Capture analysis output and metrics
        scratchpad_output=$(analyze_scratchpad "$scratchpad_file" "$run_number" 2>&1)

        # Extract the last line which contains CSV metrics
        scratchpad_metrics=$(echo "$scratchpad_output" | tail -n 1)
        scratchpad_display=$(echo "$scratchpad_output" | head -n -1)

        # Add analysis to report
        echo "$scratchpad_display" >> "$SUITE_REPORT"

        # Parse metrics for aggregation
        if [[ "$scratchpad_metrics" =~ ^[0-9] ]]; then
          IFS=',' read -r lines phases_comp phases_fail completion_pct errors warnings status stage <<< "$scratchpad_metrics"
          total_scratchpad_lines=$((total_scratchpad_lines + lines))
          total_phases_completed=$((total_phases_completed + phases_comp))
          total_phases_failed=$((total_phases_failed + phases_fail))
          total_scratchpad_errors=$((total_scratchpad_errors + errors))
          total_scratchpad_warnings=$((total_scratchpad_warnings + warnings))

          case "$status" in
            "completed") completed_workflows=$((completed_workflows + 1)) ;;
            "partial") partial_workflows=$((partial_workflows + 1)) ;;
            "failed") failed_scratchpad_workflows=$((failed_scratchpad_workflows + 1)) ;;
          esac
        fi
      fi
    done
    echo "" >> "$SUITE_REPORT"
  fi
done

echo "  Summary:" >> "$SUITE_REPORT"
echo "    Total runs with claude log artifacts: $actual_runs" >> "$SUITE_REPORT"
echo "    Total runs with scratchpad artifacts: $scratchpad_runs" >> "$SUITE_REPORT"
echo "    Total claude log files: $total_claude_logs" >> "$SUITE_REPORT"
echo "    Total scratchpad files: $total_scratchpad" >> "$SUITE_REPORT"
echo "" >> "$SUITE_REPORT"

echo "  Workflow Execution Metrics:" >> "$SUITE_REPORT"
echo "    Successful workflows: $successful_workflows" >> "$SUITE_REPORT"
echo "    Failed workflows: $failed_workflows" >> "$SUITE_REPORT"
if [[ $((successful_workflows + failed_workflows)) -gt 0 ]]; then
  success_rate=$(( (successful_workflows * 100) / (successful_workflows + failed_workflows) ))
  echo "    Success rate: $success_rate%" >> "$SUITE_REPORT"
fi
echo "" >> "$SUITE_REPORT"

echo "  Tool Usage Metrics:" >> "$SUITE_REPORT"
echo "    Total messages: $total_messages" >> "$SUITE_REPORT"
echo "    Total tool calls: $total_tool_calls" >> "$SUITE_REPORT"
echo "    Successful tool calls: $total_successful_tools" >> "$SUITE_REPORT"
echo "    Failed tool calls: $total_failed_tools" >> "$SUITE_REPORT"
if [[ $total_tool_calls -gt 0 ]]; then
  tool_success_rate=$(( (total_successful_tools * 100) / total_tool_calls ))
  echo "    Tool success rate: $tool_success_rate%" >> "$SUITE_REPORT"
fi
if [ "$actual_runs" -gt 0 ]; then
  echo "    Average claude log files per run: $((total_claude_logs / actual_runs))" >> "$SUITE_REPORT"
  echo "    Average tool calls per run: $((total_tool_calls / actual_runs))" >> "$SUITE_REPORT"
fi
if [ "$scratchpad_runs" -gt 0 ]; then
  echo "    Average scratchpad files per run: $((total_scratchpad / scratchpad_runs))" >> "$SUITE_REPORT"
fi
echo "" >> "$SUITE_REPORT"

echo "  Workflow Progress Metrics:" >> "$SUITE_REPORT"
echo "    Completed workflows (via scratchpad): $completed_workflows" >> "$SUITE_REPORT"
echo "    Partially completed workflows: $partial_workflows" >> "$SUITE_REPORT"
echo "    Failed workflows (via scratchpad): $failed_scratchpad_workflows" >> "$SUITE_REPORT"
echo "    Total phases completed: $total_phases_completed" >> "$SUITE_REPORT"
echo "    Total phases failed: $total_phases_failed" >> "$SUITE_REPORT"
echo "    Total scratchpad errors: $total_scratchpad_errors" >> "$SUITE_REPORT"
echo "    Total scratchpad warnings: $total_scratchpad_warnings" >> "$SUITE_REPORT"
if [[ $scratchpad_runs -gt 0 ]]; then
  avg_phases_per_run=$(( total_phases_completed / scratchpad_runs ))
  echo "    Average phases completed per run: $avg_phases_per_run" >> "$SUITE_REPORT"
fi
echo "" >> "$SUITE_REPORT"

echo "  Recipe Precision Metrics:" >> "$SUITE_REPORT"
if [[ $precision_analyses -gt 0 ]]; then
  # Calculate averages
  avg_precision=$(echo "scale=2; $total_precision / $precision_analyses * 100" | bc -l)
  avg_recall=$(echo "scale=2; $total_recall / $precision_analyses * 100" | bc -l)
  avg_f1=$(echo "scale=2; $total_f1 / $precision_analyses * 100" | bc -l)
  avg_accuracy=$(echo "scale=2; $total_accuracy / $precision_analyses * 100" | bc -l)

  echo "    Analyzed runs: $precision_analyses" >> "$SUITE_REPORT"
  echo "    Average precision: ${avg_precision}%" >> "$SUITE_REPORT"
  echo "    Average recall: ${avg_recall}%" >> "$SUITE_REPORT"
  echo "    Average F1 score: ${avg_f1}%" >> "$SUITE_REPORT"
  echo "    Average accuracy: ${avg_accuracy}%" >> "$SUITE_REPORT"
  echo "    Total exact matches: $total_exact_matches" >> "$SUITE_REPORT"
  echo "    Total missing changes: $total_missing_changes" >> "$SUITE_REPORT"
  echo "    Total unnecessary changes: $total_unnecessary_changes" >> "$SUITE_REPORT"

  # Recipe effectiveness assessment
  if [[ $(echo "$avg_accuracy >= 90" | bc -l) -eq 1 ]]; then
    echo "    Assessment: Excellent recipe precision" >> "$SUITE_REPORT"
  elif [[ $(echo "$avg_accuracy >= 70" | bc -l) -eq 1 ]]; then
    echo "    Assessment: Good recipe precision" >> "$SUITE_REPORT"
  elif [[ $(echo "$avg_accuracy >= 50" | bc -l) -eq 1 ]]; then
    echo "    Assessment: Moderate recipe precision - needs improvement" >> "$SUITE_REPORT"
  else
    echo "    Assessment: Poor recipe precision - significant refinement needed" >> "$SUITE_REPORT"
  fi
else
  echo "    No PR precision analysis performed" >> "$SUITE_REPORT"
fi
echo "" >> "$SUITE_REPORT"

# Display final summary
echo "========================================="
echo "SIMPLE SUITE EVAL - FINAL SUMMARY"
echo "========================================="
cat "$SUITE_REPORT"

log "Analysis complete. Results saved to $SUITE_REPORT"