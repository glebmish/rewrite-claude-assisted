#!/bin/bash

set -euo pipefail

# Usage: download-suite-artifacts.sh <suite_name> [hours_lookback] [workflow_run_ids]

SUITE_NAME="${1:-}"
HOURS_LOOKBACK="${2:-24}"
WORKFLOW_RUN_IDS="${3:-}"

if [ -z "$SUITE_NAME" ]; then
    echo "❌ Suite name is required"
    echo "Usage: $0 <suite_name> [hours_lookback] [workflow_run_ids]"
    exit 1
fi

REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
    echo "❌ GITHUB_REPOSITORY environment variable not set"
    exit 1
fi

mkdir -p artifacts

echo "🔍 Searching for workflows from suite: $SUITE_NAME"
echo ""

# Determine run IDs to process
declare -a RUN_IDS

if [ -n "$WORKFLOW_RUN_IDS" ]; then
    echo "📋 Using provided workflow run IDs"
    IFS=',' read -ra RUN_IDS <<< "$WORKFLOW_RUN_IDS"
else
    echo "🔍 Auto-discovering recent batch workflow runs"
    echo "   Looking back: $HOURS_LOOKBACK hours"

    SINCE=$(date -u -d "$HOURS_LOOKBACK hours ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-${HOURS_LOOKBACK}H '+%Y-%m-%dT%H:%M:%SZ')

    # Get all workflow runs for this suite
    all_runs=$(gh api "/repos/$REPO/actions/runs?created=>$SINCE&status=completed&per_page=100" \
      --jq ".workflow_runs[] | select(.name | startswith(\"$SUITE_NAME - Batch\")) | {id: .id, name: .name, created_at: .created_at}")

    if [ -z "$all_runs" ]; then
        echo "❌ No completed batch workflow runs found for suite: $SUITE_NAME"
        echo "💡 Tip: Make sure batch workflows have completed, or provide specific run IDs"
        exit 1
    fi

    # Group by batch number and get the latest run for each batch
    declare -A latest_runs

    while IFS= read -r run; do
        run_id=$(echo "$run" | jq -r '.id')
        run_name=$(echo "$run" | jq -r '.name')
        created_at=$(echo "$run" | jq -r '.created_at')

        # Extract batch number from name (e.g., "vintage-api-evaluation - Batch 2" -> "2")
        if [[ "$run_name" =~ Batch[[:space:]]+([0-9]+) ]]; then
            batch_num="${BASH_REMATCH[1]}"

            # Check if this is the latest run for this batch
            if [ -z "${latest_runs[$batch_num]:-}" ]; then
                # First run for this batch
                latest_runs[$batch_num]="$run_id|$created_at|$run_name"
            else
                # Compare timestamps to keep the latest
                IFS='|' read -r existing_id existing_time existing_name <<< "${latest_runs[$batch_num]}"

                if [[ "$created_at" > "$existing_time" ]]; then
                    latest_runs[$batch_num]="$run_id|$created_at|$run_name"
                fi
            fi
        fi
    done <<< "$(echo "$all_runs" | jq -c '.')"

    # Extract run IDs from latest_runs
    echo ""
    echo "📦 Latest run for each batch:"
    for batch_num in $(echo "${!latest_runs[@]}" | tr ' ' '\n' | sort -n); do
        IFS='|' read -r run_id created_at run_name <<< "${latest_runs[$batch_num]}"
        echo "   Batch $batch_num: Run ID $run_id ($run_name)"
        RUN_IDS+=("$run_id")
    done
fi

if [ ${#RUN_IDS[@]} -eq 0 ]; then
    echo "❌ No workflow runs to process"
    exit 1
fi

echo ""
echo "📥 Downloading artifacts from ${#RUN_IDS[@]} workflow run(s)..."
echo ""

# Download artifacts from each run
for run_id in "${RUN_IDS[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Processing run ID: $run_id"

    # Get workflow run info
    run_info=$(gh api "/repos/$REPO/actions/runs/$run_id")
    run_name=$(echo "$run_info" | jq -r '.name')
    run_status=$(echo "$run_info" | jq -r '.conclusion')
    run_url=$(echo "$run_info" | jq -r '.html_url')

    echo "  Name: $run_name"
    echo "  Status: $run_status"
    echo "  URL: $run_url"
    echo ""

    # List artifacts for this run
    artifacts=$(gh api "/repos/$REPO/actions/runs/$run_id/artifacts" --jq '.artifacts[]')

    if [ -z "$artifacts" ]; then
        echo "  ⚠️  No artifacts found"
        echo ""
        continue
    fi

    artifact_count=0

    # Download each artifact
    while IFS= read -r artifact; do
        artifact_name=$(echo "$artifact" | jq -r '.name')
        artifact_id=$(echo "$artifact" | jq -r '.id')

        # Only download run-metadata artifacts
        if [[ "$artifact_name" == *"run-metadata"* ]]; then
            echo "  📥 Downloading: $artifact_name"

            # Download and extract
            gh api "/repos/$REPO/actions/artifacts/$artifact_id/zip" > "artifacts/${artifact_name}.zip"
            unzip -q "artifacts/${artifact_name}.zip" -d "artifacts/${artifact_name}"
            rm "artifacts/${artifact_name}.zip"

            artifact_count=$((artifact_count + 1))
        fi
    done <<< "$(echo "$artifacts" | jq -c '.')"

    echo "  ✅ Downloaded $artifact_count artifact(s)"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All artifacts downloaded successfully!"
echo ""

# Count total artifacts
total_artifacts=$(find artifacts -type d -name "*run-metadata*" | wc -l)
echo "📊 Total artifacts: $total_artifacts"