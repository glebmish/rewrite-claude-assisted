#!/bin/bash

# Claude Usage Statistics Script
# Analyzes Claude JSONL log files to extract usage metrics

set -euo pipefail

# Function to show usage
usage() {
    echo "Usage: $0 <log_file_path>"
    echo "  log_file_path: Path to Claude JSONL log file"
    echo ""
    echo "Outputs JSON results to the same directory as the input log file"
    exit 1
}

# Check arguments
if [[ $# -ne 1 ]]; then
    usage
fi

LOG_FILE="$1"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: Log file not found: $LOG_FILE"
    exit 1
fi

# Get output directory from log file path
OUTPUT_DIR="$(dirname "$LOG_FILE")"
OUTPUT_FILE="$OUTPUT_DIR/claude-usage-stats.json"

# Initialize counters
total_messages=0
tool_calls=0
successful_tools=0
failed_tools=0

# Tool usage tracking (use associative array to get unique tools)
declare -A tool_usage

echo "Analyzing Claude log: $LOG_FILE"

# Parse JSONL file line by line
while IFS= read -r line; do
    if [[ -n "$line" && "$line" != "null" ]]; then
        total_messages=$((total_messages + 1))

        # Check for tool calls (in assistant messages with content array containing tool_use)
        tool_name=$(echo "$line" | jq -r '.message.content[]? | select(.type == "tool_use") | .name // empty' 2>/dev/null || echo "")
        if [[ -n "$tool_name" && "$tool_name" != "null" ]]; then
            tool_calls=$((tool_calls + 1))

            # For Bash tools, extract first word from the command; for others use the tool name
            if [[ "$tool_name" == "Bash" ]]; then
                # Extract the command from the input field
                bash_command=$(echo "$line" | jq -r '.message.content[] | select(.type == "tool_use" and .name == "Bash") | .input.command // empty' 2>/dev/null || echo "")
                if [[ -n "$bash_command" && "$bash_command" != "null" ]]; then
                    # Get first word of the command, safely handling special cases
                    first_line=$(echo "$bash_command" | head -n1)
                    first_word=$(echo "$first_line" | awk '{print $1}')
                    # Remove path if present (e.g., "/usr/bin/git" -> "git")
                    tool_base=$(basename "$first_word")

                    # Handle special script names that should be preserved
                    if [[ "$tool_base" == "get-session-id.sh" ]] || [[ "$tool_base" == "run-option-b.sh" ]]; then
                        # Keep script names as-is
                        true
                    elif [[ "$tool_base" == "" ]]; then
                        tool_base="bash"
                    fi
                else
                    tool_base="bash"
                fi
            else
                tool_base="$tool_name"
            fi

            tool_usage["$tool_base"]=$((${tool_usage["$tool_base"]:-0} + 1))
        fi

        # Check for tool results (in user messages with content array containing tool_result)
        has_tool_result=$(echo "$line" | jq -r '.message.content[]? | select(.type == "tool_result") | .type // empty' 2>/dev/null || echo "")
        if [[ "$has_tool_result" == "tool_result" ]]; then
            is_error=$(echo "$line" | jq -r '.message.content[] | select(.type == "tool_result") | .is_error // false' 2>/dev/null || echo "false")
            if [[ "$is_error" == "true" ]]; then
                failed_tools=$((failed_tools + 1))
            else
                successful_tools=$((successful_tools + 1))
            fi
        fi
    fi
done < "$LOG_FILE"

# Calculate tool success rate
if [[ $tool_calls -gt 0 ]]; then
    tool_success_rate=$(echo "scale=4; $successful_tools / $tool_calls" | bc -l)
else
    tool_success_rate="0"
fi

# Build tools used set (sorted for consistency)
tools_used_array=()
for tool in "${!tool_usage[@]}"; do
    tools_used_array+=("$tool")
done

# Sort the tools for consistent output
IFS=$'\n' tools_used_sorted=($(printf '%s\n' "${tools_used_array[@]}" | sort))

# Create JSON output manually to avoid complex jq issues
cat > "$OUTPUT_FILE" << EOF
{
  "log_file": "$LOG_FILE",
  "analysis_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "metrics": {
    "total_messages": $total_messages,
    "tool_calls": $tool_calls,
    "successful_tool_calls": $successful_tools,
    "failed_tool_calls": $failed_tools,
    "tool_success_rate": $tool_success_rate,
    "tools_used": [$(printf '"%s"' "${tools_used_sorted[0]}"
      for ((i=1; i<${#tools_used_sorted[@]}; i++)); do
        printf ', "%s"' "${tools_used_sorted[i]}"
      done
    )],
    "tool_usage_breakdown": {$(
      first=true
      for tool in "${tools_used_sorted[@]}"; do
        if [[ "$first" == "true" ]]; then
          printf '"%s": %d' "$tool" "${tool_usage[$tool]}"
          first=false
        else
          printf ', "%s": %d' "$tool" "${tool_usage[$tool]}"
        fi
      done
    )}
  }
}
EOF

echo "Usage statistics saved to: $OUTPUT_FILE"

# Output summary to stdout
echo ""
echo "Usage Statistics Summary:"
echo "  Total messages: $total_messages"
echo "  Tool calls: $tool_calls"
echo "  Successful tool calls: $successful_tools"
echo "  Failed tool calls: $failed_tools"
echo "  Tools used: ${#tool_usage[@]}"
if [[ $tool_calls -gt 0 ]]; then
    success_rate=$(echo "scale=1; $successful_tools * 100 / $tool_calls" | bc -l)
    echo "  Tool success rate: ${success_rate}%"
fi