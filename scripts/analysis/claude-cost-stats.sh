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

# Use jq to extract usage data, group by model, apply model-specific pricing, and create the cost JSON
cat "$LOG_FILE" | jq -s --arg log_file "$LOG_FILE" '
  # Define pricing for each model (per million tokens)
  {
    "claude-sonnet-4-5": {
      input: 3.00,
      output: 15.00,
      cache_creation: 3.75,
      cache_read: 0.30
    },
    "claude-haiku-4-5": {
      input: 1.00,
      output: 5.00,
      cache_creation: 1.25,
      cache_read: 0.10
    },
    "claude-3-5-haiku": {
      input: 0.80,
      output: 4.00,
      cache_creation: 1.00,
      cache_read: 0.08
    }
  } as $pricing |

  # Group messages by model
  (map(select(.message.usage != null and .message.model != null) | {model: .message.model, usage: .message.usage}) | group_by(.model)) as $by_model |

  # Calculate per-model usage and costs
  ($by_model | map((.[0].model) as $model | {
    model: $model,
    usage: {
      input_tokens: map(.usage.input_tokens // 0) | add,
      cache_creation_input_tokens: map(.usage.cache_creation_input_tokens // 0) | add,
      cache_read_input_tokens: map(.usage.cache_read_input_tokens // 0) | add,
      output_tokens: map(.usage.output_tokens // 0) | add
    }
  } | . + {
    costs: (
        ([$pricing | to_entries[] | (.key) as $kk | select($model | startswith($kk))] | .[0].value // {input:3.00, output: 15.00, cache_creation: 3.75, cache_read: 0.30}) as $p |
      {
        input_tokens_cost: (.usage.input_tokens * $p.input / 1000000),
        cache_creation_input_tokens_cost: (.usage.cache_creation_input_tokens * $p.cache_creation / 1000000),
        cache_read_input_tokens_cost: (.usage.cache_read_input_tokens * $p.cache_read / 1000000),
        output_tokens_cost: (.usage.output_tokens * $p.output / 1000000)
      } | . + {
        total_cost: (.input_tokens_cost + .cache_creation_input_tokens_cost + .cache_read_input_tokens_cost + .output_tokens_cost)
      }
    )
  })) as $model_stats |

  {
    log_file: $log_file,
    analysis_timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
    by_model: $model_stats,
    totals: {
      usage: {
        input_tokens: ($model_stats | map(.usage.input_tokens) | add),
        cache_creation_input_tokens: ($model_stats | map(.usage.cache_creation_input_tokens) | add),
        cache_read_input_tokens: ($model_stats | map(.usage.cache_read_input_tokens) | add),
        output_tokens: ($model_stats | map(.usage.output_tokens) | add)
      },
      costs: {
        input_tokens_cost: ($model_stats | map(.costs.input_tokens_cost) | add),
        cache_creation_input_tokens_cost: ($model_stats | map(.costs.cache_creation_input_tokens_cost) | add),
        cache_read_input_tokens_cost: ($model_stats | map(.costs.cache_read_input_tokens_cost) | add),
        output_tokens_cost: ($model_stats | map(.costs.output_tokens_cost) | add),
        total_cost: ($model_stats | map(.costs.total_cost) | add)
      }
    }
  }
' > "$OUTPUT_FILE"

echo "Cost statistics saved to: $OUTPUT_FILE"

# Output summary to stdout
echo ""
echo "Cost Statistics Summary:"
echo ""

# Display per-model costs
jq -r '.by_model[] | "Model: \(.model)\n  Input tokens: \(.usage.input_tokens)\n  Cache creation tokens: \(.usage.cache_creation_input_tokens)\n  Cache read tokens: \(.usage.cache_read_input_tokens)\n  Output tokens: \(.usage.output_tokens)\n  Cost: $" + (.costs.total_cost | tostring) + "\n"' "$OUTPUT_FILE"

# Extract and display totals
TOTAL_COST=$(jq -r '.totals.costs.total_cost' "$OUTPUT_FILE")
INPUT_TOKENS=$(jq -r '.totals.usage.input_tokens' "$OUTPUT_FILE")
OUTPUT_TOKENS=$(jq -r '.totals.usage.output_tokens' "$OUTPUT_FILE")
CACHE_CREATION_TOKENS=$(jq -r '.totals.usage.cache_creation_input_tokens' "$OUTPUT_FILE")
CACHE_READ_TOKENS=$(jq -r '.totals.usage.cache_read_input_tokens' "$OUTPUT_FILE")

echo "Total across all models:"
echo "  Total cost: \$$(printf "%.4f" "$TOTAL_COST")"
echo "  Input tokens: $INPUT_TOKENS"
echo "  Output tokens: $OUTPUT_TOKENS"
echo "  Cache creation tokens: $CACHE_CREATION_TOKENS"
echo "  Cache read tokens: $CACHE_READ_TOKENS"