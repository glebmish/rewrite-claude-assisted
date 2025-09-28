#!/bin/bash

# Scratchpad Analysis Script
# Analyzes scratchpad files to extract workflow progress and phase completion status

set -euo pipefail

# Function to analyze a single scratchpad file
analyze_scratchpad() {
    local scratchpad_file="$1"
    local run_number="$2"

    if [[ ! -f "$scratchpad_file" ]]; then
        echo "    Warning: Scratchpad file not found: $scratchpad_file"
        return 1
    fi

    echo "    Analyzing scratchpad for run $run_number..."

    # Initialize tracking variables
    local total_lines=0
    local session_id=""
    local phases_completed=0
    local phases_failed=0
    local last_phase=""
    local workflow_stage="unknown"

    # Phase tracking
    declare -A phase_status
    local phases=("fetch-repos" "extract-intent" "recipe-mapping" "recipe-validation")

    # Error and warning tracking
    local errors=()
    local warnings=()

    # Read and analyze the scratchpad
    while IFS= read -r line; do
        total_lines=$((total_lines + 1))

        # Extract session ID (should be on first line)
        if [[ -z "$session_id" && "$line" =~ Session\ ID:\ ([a-f0-9-]+) ]]; then
            session_id="${BASH_REMATCH[1]}"
        fi

        # Track phase execution
        for phase in "${phases[@]}"; do
            if [[ "$line" =~ /$phase|Phase.*$phase ]]; then
                last_phase="$phase"
                if [[ "$line" =~ (completed|success|finished) ]]; then
                    phase_status["$phase"]="completed"
                    phases_completed=$((phases_completed + 1))
                elif [[ "$line" =~ (failed|error|abort) ]]; then
                    phase_status["$phase"]="failed"
                    phases_failed=$((phases_failed + 1))
                else
                    phase_status["$phase"]="started"
                fi
            fi
        done

        # Detect workflow stage
        if [[ "$line" =~ "Repository Setup" || "$line" =~ "fetch-repos" ]]; then
            workflow_stage="repository-setup"
        elif [[ "$line" =~ "Intent Analysis" || "$line" =~ "extract-intent" ]]; then
            workflow_stage="intent-analysis"
        elif [[ "$line" =~ "Recipe Mapping" || "$line" =~ "recipe-mapping" ]]; then
            workflow_stage="recipe-mapping"
        elif [[ "$line" =~ "Recipe validation" || "$line" =~ "recipe-validation" ]]; then
            workflow_stage="recipe-validation"
        fi

        # Collect errors and warnings
        if [[ "$line" =~ [Ee]rror|[Ff]ailed|Exception ]]; then
            errors+=("$(echo "$line" | head -c 150)")
        elif [[ "$line" =~ [Ww]arning|[Ww]arn ]]; then
            warnings+=("$(echo "$line" | head -c 150)")
        fi

    done < "$scratchpad_file"

    # Calculate completion percentage
    local completion_pct=0
    if [[ ${#phases[@]} -gt 0 ]]; then
        completion_pct=$(( (phases_completed * 100) / ${#phases[@]} ))
    fi

    # Output analysis results
    echo "      Lines: $total_lines"
    echo "      Session ID: ${session_id:-'not found'}"
    echo "      Workflow stage: $workflow_stage"
    echo "      Last phase: ${last_phase:-'none detected'}"
    echo "      Phases completed: $phases_completed/${#phases[@]} ($completion_pct%)"
    echo "      Phases failed: $phases_failed"

    # Show phase status
    echo "      Phase status:"
    for phase in "${phases[@]}"; do
        local status="${phase_status[$phase]:-'not started'}"
        echo "        $phase: $status"
    done

    # Show errors and warnings summary
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "      Errors found: ${#errors[@]}"
        for error in "${errors[@]:0:2}"; do  # Show first 2 errors
            echo "        - $error"
        done
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo "      Warnings found: ${#warnings[@]}"
    fi

    echo ""

    # Return metrics for aggregation (CSV format)
    local overall_status="unknown"
    if [[ $phases_failed -gt 0 ]]; then
        overall_status="failed"
    elif [[ $phases_completed -eq ${#phases[@]} ]]; then
        overall_status="completed"
    elif [[ $phases_completed -gt 0 ]]; then
        overall_status="partial"
    fi

    echo "$total_lines,$phases_completed,$phases_failed,$completion_pct,${#errors[@]},${#warnings[@]},$overall_status,$workflow_stage"
}

# Export function for use by main script
export -f analyze_scratchpad