#!/bin/bash

# Claude Log Analysis Script
# Analyzes Claude JSONL log files to extract meaningful metrics

set -euo pipefail

# Function to analyze a single Claude log file (JSONL format)
analyze_claude_log() {
    local log_file="$1"
    local run_number="$2"

    if [[ ! -f "$log_file" ]]; then
        echo "    Warning: Log file not found: $log_file"
        return 1
    fi

    # Initialize counters
    local total_messages=0
    local tool_calls=0
    local successful_tools=0
    local failed_tools=0
    local start_time=""
    local end_time=""
    local workflow_status="unknown"

    # Tool usage counters
    declare -A tool_usage

    # Error tracking
    local errors=()

    echo "    Analyzing Claude log for run $run_number..."

    # Parse JSONL file line by line
    while IFS= read -r line; do
        if [[ -n "$line" && "$line" != "null" ]]; then
            total_messages=$((total_messages + 1))

            # Extract timestamp for duration calculation
            if [[ -z "$start_time" ]]; then
                start_time=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null || echo "")
            fi
            end_time=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null || echo "")

            # Check for tool calls
            local tool_name=$(echo "$line" | jq -r '.content[]?.name // empty' 2>/dev/null || echo "")
            if [[ -n "$tool_name" && "$tool_name" != "null" ]]; then
                tool_calls=$((tool_calls + 1))
                tool_usage["$tool_name"]=$((${tool_usage["$tool_name"]:-0} + 1))
            fi

            # Check for tool results/errors
            local tool_result=$(echo "$line" | jq -r '.content[]?.type // empty' 2>/dev/null || echo "")
            if [[ "$tool_result" == "tool_result" ]]; then
                local is_error=$(echo "$line" | jq -r '.content[]?.is_error // false' 2>/dev/null || echo "false")
                if [[ "$is_error" == "true" ]]; then
                    failed_tools=$((failed_tools + 1))
                    local error_msg=$(echo "$line" | jq -r '.content[]?.content // empty' 2>/dev/null || echo "")
                    if [[ -n "$error_msg" ]]; then
                        errors+=("$error_msg")
                    fi
                else
                    successful_tools=$((successful_tools + 1))
                fi
            fi

            # Check for workflow completion indicators
            local message_content=$(echo "$line" | jq -r '.content[]?.text // empty' 2>/dev/null || echo "")
            if [[ "$message_content" =~ "workflow.*complete" ]] || [[ "$message_content" =~ "successfully.*completed" ]]; then
                workflow_status="success"
            elif [[ "$message_content" =~ "workflow.*failed" ]] || [[ "$message_content" =~ "error" ]] || [[ "$message_content" =~ "failed" ]]; then
                workflow_status="failure"
            fi
        fi
    done < "$log_file"

    # Calculate duration if timestamps available
    local duration="unknown"
    if [[ -n "$start_time" && -n "$end_time" && "$start_time" != "null" && "$end_time" != "null" ]]; then
        local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
        local end_epoch=$(date -d "$end_time" +%s 2>/dev/null || echo "0")
        if [[ "$start_epoch" -gt 0 && "$end_epoch" -gt 0 && "$end_epoch" -ge "$start_epoch" ]]; then
            duration=$((end_epoch - start_epoch))
        fi
    fi

    # Output analysis results
    echo "      Messages: $total_messages"
    echo "      Tool calls: $tool_calls (successful: $successful_tools, failed: $failed_tools)"
    echo "      Duration: $duration seconds"
    echo "      Workflow status: $workflow_status"

    # Show top tools used
    if [[ ${#tool_usage[@]} -gt 0 ]]; then
        echo "      Top tools used:"
        for tool in "${!tool_usage[@]}"; do
            echo "        $tool: ${tool_usage[$tool]} times"
        done | sort -k2 -nr | head -5
    fi

    # Show errors if any
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "      Errors encountered: ${#errors[@]}"
        for error in "${errors[@]:0:3}"; do  # Show first 3 errors
            echo "        - $(echo "$error" | head -c 100)..."
        done
    fi

    echo ""

    # Return metrics for aggregation
    echo "$total_messages,$tool_calls,$successful_tools,$failed_tools,$duration,$workflow_status"
}

# Export function for use by main script
export -f analyze_claude_log