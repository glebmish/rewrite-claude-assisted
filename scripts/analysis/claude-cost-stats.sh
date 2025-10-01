#!/bin/bash

# Claude Cost Statistics Script
# Calculates API usage costs from Claude JSONL log files

set -euo pipefail

# Function to show usage
usage() {
    echo "Usage: $0 <log_file_path>"
    echo "  log_file_path: Path to Claude JSONL log file"
    echo ""
    echo "Outputs JSON cost results to the same directory as the input log file"
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
OUTPUT_FILE="$OUTPUT_DIR/claude-cost-stats.json"

echo "Calculating usage costs for: $LOG_FILE"

# Claude Sonnet 4 pricing constants (per million tokens)
PRICE_INPUT_TOKENS=3.00              # Base input tokens: $3 per million
PRICE_OUTPUT_TOKENS=15.00            # Output tokens: $15 per million
PRICE_CACHE_CREATION_TOKENS=3.75     # Cache creation (5m): $3.75 per million
PRICE_CACHE_READ_TOKENS=0.30         # Cache hits & refreshes: $0.30 per million

# Use jq to extract usage data, sum up each field, calculate costs, and create the cost JSON
cat "$LOG_FILE" | jq -s --arg price_input "$PRICE_INPUT_TOKENS" \
                        --arg price_output "$PRICE_OUTPUT_TOKENS" \
                        --arg price_cache_creation "$PRICE_CACHE_CREATION_TOKENS" \
                        --arg price_cache_read "$PRICE_CACHE_READ_TOKENS" \
                        --arg log_file "$LOG_FILE" '
  {
    log_file: $log_file,
    analysis_timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
    usage: (
      map(select(.message.usage != null) | .message.usage) |
      {
        input_tokens: map(.input_tokens // 0) | add,
        cache_creation_input_tokens: map(.cache_creation_input_tokens // 0) | add,
        cache_read_input_tokens: map(.cache_read_input_tokens // 0) | add,
        output_tokens: map(.output_tokens // 0) | add,
        service_tier: (map(.service_tier) | unique | join(", "))
      }
    ),
    costs: (
      map(select(.message.usage != null) | .message.usage) |
      {
        input_tokens: map(.input_tokens // 0) | add,
        cache_creation_input_tokens: map(.cache_creation_input_tokens // 0) | add,
        cache_read_input_tokens: map(.cache_read_input_tokens // 0) | add,
        output_tokens: map(.output_tokens // 0) | add
      } |
      {
        input_tokens_cost: (.input_tokens * ($price_input | tonumber) / 1000000),
        cache_creation_input_tokens_cost: (.cache_creation_input_tokens * ($price_cache_creation | tonumber) / 1000000),
        cache_read_input_tokens_cost: (.cache_read_input_tokens * ($price_cache_read | tonumber) / 1000000),
        output_tokens_cost: (.output_tokens * ($price_output | tonumber) / 1000000)
      } |
      . + {
        total_cost: (.input_tokens_cost + .cache_creation_input_tokens_cost + .cache_read_input_tokens_cost + .output_tokens_cost)
      }
    ),
    pricing: {
      input_tokens_per_million: ($price_input | tonumber),
      output_tokens_per_million: ($price_output | tonumber),
      cache_creation_tokens_per_million: ($price_cache_creation | tonumber),
      cache_read_tokens_per_million: ($price_cache_read | tonumber),
      currency: "USD"
    }
  }
' > "$OUTPUT_FILE"

echo "Cost statistics saved to: $OUTPUT_FILE"

# Output summary to stdout
echo ""
echo "Cost Statistics Summary:"

# Extract and display key metrics
TOTAL_COST=$(jq -r '.costs.total_cost' "$OUTPUT_FILE")
INPUT_TOKENS=$(jq -r '.usage.input_tokens' "$OUTPUT_FILE")
OUTPUT_TOKENS=$(jq -r '.usage.output_tokens' "$OUTPUT_FILE")
CACHE_CREATION_TOKENS=$(jq -r '.usage.cache_creation_input_tokens' "$OUTPUT_FILE")
CACHE_READ_TOKENS=$(jq -r '.usage.cache_read_input_tokens' "$OUTPUT_FILE")

echo "  Total cost: \$$(printf "%.4f" "$TOTAL_COST")"
echo "  Input tokens: $INPUT_TOKENS"
echo "  Output tokens: $OUTPUT_TOKENS"
echo "  Cache creation tokens: $CACHE_CREATION_TOKENS"
echo "  Cache read tokens: $CACHE_READ_TOKENS"