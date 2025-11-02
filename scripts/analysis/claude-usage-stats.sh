#!/bin/bash

# Claude Usage Statistics Script
# Analyzes Claude JSONL log files to extract usage metrics in a single pass.

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

echo "Analyzing Claude log: $LOG_FILE"

# Define the jq filter using a heredoc. The 'EOF' is quoted to prevent shell expansion.
JQ_FILTER=$(cat <<'EOF'
reduce inputs as $line (
    # Initial state for our counters and lists
    {
      total_messages: 0,
      tool_calls: 0,
      successful_tool_calls: 0,
      failed_tool_calls: 0,
      tools_used_array: [],
      failed_ids: {}
    };

    # For each line, increment total_messages and then reduce over the content array.
    .total_messages += 1
    | reduce ($line.message.content[]?) as $c (.;
        if $c.type == "tool_use" and $c.id != null then
          .tool_calls += 1
          | .tools_used_array += [{
              id: $c.id,
              text: (
                if $c.input.command != null then $c.name + "(" + ($c.input.command | @sh) + ")"
                elif $c.input.file_path != null then $c.name + "(" + ($c.input.file_path | @sh) + ")"
                elif $c.input.pattern != null then $c.name + "(" + ($c.input.pattern | @sh) + ")"
                elif $c.input.query != null then $c.name + "(" + ($c.input.query | @sh) + ")"
                elif $c.input.subagent_type != null then $c.name + "(" + ($c.input.subagent_type | @sh) + ")"
                else $c.name end
              )
          }]
        elif $c.type == "tool_result" then
          if $c.is_error == true then
            .failed_tool_calls += 1
            | .failed_ids[$c.tool_use_id] = true
          else
            .successful_tool_calls += 1
          end
        else
          .
        end
      )
)
# Post-processing after all lines are read
| .tool_success_rate = (if .tool_calls > 0 then .successful_tool_calls / .tool_calls | .*10000 | floor / 10000 else 0 end)
| .tools_used = (.tools_used_array as $tools | .failed_ids as $failed | $tools | map(if $failed[.id] then "*" + .text else .text end))
# Assemble the final JSON output
| {
    log_file: $log_file,
    analysis_timestamp: $timestamp,
    metrics: {
      total_messages: .total_messages,
      tool_calls: .tool_calls,
      successful_tool_calls: .successful_tool_calls,
      failed_tool_calls: .failed_tool_calls,
      tool_success_rate: .tool_success_rate
    },
    tools_used: .tools_used
  }
EOF
)

# Execute jq with the filter from the heredoc variable
jq -n --arg log_file "$LOG_FILE" --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$JQ_FILTER" "$LOG_FILE" > "$OUTPUT_FILE"

echo "Usage statistics saved to: $OUTPUT_FILE"

# Output summary to stdout by parsing the generated JSON file
echo ""
echo "Usage Statistics Summary:"
jq -r '
  "  Total messages: \(.metrics.total_messages)\n" +
  "  Tool calls: \(.metrics.tool_calls)\n" +
  "  Successful tool calls: \(.metrics.successful_tool_calls)\n" +
  "  Failed tool calls: \(.metrics.failed_tool_calls)\n" +
  "  Tool success rate: \(.metrics.tool_success_rate)"
' "$OUTPUT_FILE"
