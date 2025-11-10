#!/bin/bash

set -euo pipefail

# Usage: generate-suite-workflows.sh <path-to-config.yaml>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-config.yaml>"
    echo "Example: $0 eval/suite-config.yaml"
    exit 1
fi

CONFIG_FILE="$1"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "📄 Reading configuration from: $CONFIG_FILE"

# Parse YAML with yq
SUITE_NAME=$(yq eval '.suite_name' "$CONFIG_FILE")
BATCH_SIZE=$(yq eval '.batch_size' "$CONFIG_FILE")
PR_COUNT=$(yq eval '.prs | length' "$CONFIG_FILE")

if [ "$SUITE_NAME" = "null" ] || [ -z "$SUITE_NAME" ]; then
    echo "❌ suite_name not found in config"
    exit 1
fi

if [ "$BATCH_SIZE" = "null" ] || [ -z "$BATCH_SIZE" ]; then
    echo "❌ batch_size not found in config"
    exit 1
fi

if [ "$PR_COUNT" -eq 0 ]; then
    echo "❌ No PRs found in config"
    exit 1
fi

echo "📋 Suite: $SUITE_NAME"
echo "📦 Batch Size: $BATCH_SIZE"
echo "📊 PRs: $PR_COUNT"
echo ""

# Build all matrix items with pr_index
all_items=()
pr_index=0

for i in $(seq 0 $(( PR_COUNT - 1 ))); do
    pr_url=$(yq eval ".prs[$i].url" "$CONFIG_FILE")
    runs=$(yq eval ".prs[$i].runs" "$CONFIG_FILE")
    pr_num=$(echo "$pr_url" | grep -oE '[0-9]+$')

    echo "  [$pr_index] PR #$pr_num: $runs run(s)"

    for run in $(seq 1 "$runs"); do
        all_items+=("$pr_url|$pr_num|$pr_index|$run|$runs")
    done

    pr_index=$((pr_index + 1))
done

total_runs=${#all_items[@]}
num_batches=$(( (total_runs + BATCH_SIZE - 1) / BATCH_SIZE ))

echo ""
echo "📦 Total runs: $total_runs"
echo "📦 Number of batches: $num_batches"
echo ""

# Create workflows directory if it doesn't exist
WORKFLOWS_DIR=".github/workflows"
mkdir -p "$WORKFLOWS_DIR"

# Generate batch workflows
echo "🔧 Generating batch workflows..."

for batch_num in $(seq 0 "$((num_batches - 1))"); do
    start_idx=$(( batch_num * BATCH_SIZE ))
    end_idx=$(( (batch_num) + 1 * BATCH_SIZE ))

    workflow_file="$WORKFLOWS_DIR/${SUITE_NAME}-batch-${batch_num}.yml"

    cat > "$workflow_file" << EOF
name: '${SUITE_NAME} - Batch ${batch_num}'

on:
  workflow_dispatch:

permissions:
  contents: read
  pull-requests: read

jobs:
  run-batch:
    name: 'PR \${{ matrix.pr_num }} Run \${{ matrix.run }}/\${{ matrix.total_runs }}'
    strategy:
      matrix:
        include:
EOF

    # Add matrix items for this batch
    for idx in $(seq $start_idx $(( end_idx - 1 ))); do
        if [ $idx -lt $total_runs ]; then
            IFS='|' read -r pr_url pr_num pr_idx run total_runs_val <<< "${all_items[$idx]}"

            cat >> "$workflow_file" << EOF
          - pr_url: "$pr_url"
            pr_num: "$pr_num"
            pr_index: $pr_idx
            run: $run
            total_runs: $total_runs_val
EOF
        fi
    done

    cat >> "$workflow_file" << EOF
      max-parallel: 1
      fail-fast: false
    uses: ./.github/workflows/rewrite-assist.yml
    with:
      pr_url: \${{ matrix.pr_url }}
      strict_mode: false
      artifact_prefix: \${{ matrix.pr_index }}-run\${{ matrix.run }}
    secrets: inherit
EOF

    echo "  ✅ Created: $workflow_file"
done

# Generate aggregator workflow
echo ""
echo "🔧 Generating aggregator workflow..."

aggregator_file="$WORKFLOWS_DIR/${SUITE_NAME}-aggregate.yml"

cat > "$aggregator_file" << EOF
name: '${SUITE_NAME} - Aggregate Results'

on:
  workflow_dispatch:
    inputs:
      workflow_runs:
        description: 'Comma-separated workflow run IDs to aggregate (leave empty to auto-discover latest batch runs)'
        required: false
        type: string
      hours_lookback:
        description: 'Hours to look back for auto-discovery (default: 24)'
        required: false
        default: '24'
        type: string

permissions:
  contents: read
  actions: read

jobs:
  aggregate:
    runs-on: ubuntu-latest
    name: 'Download and Aggregate Results'

    steps:
      - name: 'Checkout repository'
        uses: actions/checkout@v4

      - name: 'Download artifacts from batch runs'
        env:
          GH_TOKEN: \${{ github.token }}
        run: |
          eval/download-suite-artifacts.sh \\
            "${SUITE_NAME}" \\
            "\${{ inputs.hours_lookback }}" \\
            "\${{ inputs.workflow_runs }}"

      - name: 'Analyze and generate suite summary'
        run: |
          eval/analyze-suite-results.sh "artifacts/"

      - name: 'Upload aggregated results'
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: ${SUITE_NAME}-aggregated-results
          path: suite-results/
          if-no-files-found: ignore
EOF

echo "  ✅ Created: $aggregator_file"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Suite workflows generated successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Generated workflows:"
for batch_num in $(seq 0 "$((num_batches - 1))"); do
    echo "  • ${SUITE_NAME}-batch-${batch_num}.yml"
done
echo "  • ${SUITE_NAME}-aggregate.yml"
echo ""
echo "📖 Next steps:"
echo "  1. Review generated workflows in $WORKFLOWS_DIR/"
echo "  2. Commit and push to GitHub"
echo "  3. Run batches manually in GitHub Actions:"
for batch_num in $(seq 0 "$((num_batches - 1))"); do
    echo "     ${batch_num}. Actions → '${SUITE_NAME} - Batch ${batch_num}' → Run workflow"
    [ $batch_num -lt $num_batches ] && echo "        ⏰ Wait 5 hours"
done
echo "  4. After all batches complete:"
echo "     Actions → '${SUITE_NAME} - Aggregate Results' → Run workflow"
echo ""