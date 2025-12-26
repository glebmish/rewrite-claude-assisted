#!/bin/bash
set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

# Determine directories
EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$EVAL_DIR/.." && pwd)"
PLUGIN_DIR="$PROJECT_ROOT/plugin"

# Initialize variables
OUTPUT_DIR=""
SESSION_ID=""

# Function to show usage
usage() {
    echo "Usage: $0 -d <output-directory> -s <session-id>"
    echo "  -d: Path to output dir"
    echo "  -s: Session ID (UUID format)"
    exit 1
}

# Parse command line arguments
while getopts "d:s:h" opt; do
    case $opt in
        d)
            OUTPUT_DIR="$OPTARG"
            ;;
        s)
            SESSION_ID="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$OUTPUT_DIR" ]]; then
    echo "Error: output directory required (-d)"
    usage
fi

if [[ -z "$SESSION_ID" ]]; then
    echo "Error: session ID required (-s)"
    usage
fi

# Validate output directory exists
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Error: output directory not found: $OUTPUT_DIR"
    exit 1
fi

log "Starting analysis for: $OUTPUT_DIR"
log "Session ID: $SESSION_ID"

# Phase 1: Fetch session log
log "Phase 1: Fetching Claude session log..."

LOG_DIR="$OUTPUT_DIR/log"
SESSION_LOG="$LOG_DIR/$SESSION_ID.jsonl"

# Fetch session using existing script
if ! "$PLUGIN_DIR/scripts/fetch-session.sh" -s "$SESSION_ID" -o "$LOG_DIR"; then
    log "Error: Failed to fetch session log"
    exit 1
fi
log "Session log saved to: $SESSION_LOG"
SESSION_FETCH_FAILED=false

# Phase 2: Quantitative analysis (combined usage and cost stats)
log "Phase 2: Running quantitative analysis..."

log "  Running usage and cost stats analysis..."
if "$PROJECT_ROOT/scripts/claude-stats.py" "$SESSION_LOG" -o "$OUTPUT_DIR"; then
    log "  Usage stats saved to: $OUTPUT_DIR/claude-usage-stats.json"
    log "  Cost stats saved to: $OUTPUT_DIR/claude-cost-stats.json"
else
    log "  Warning: Stats analysis failed"
fi

log "Quantitative analysis complete"


# Phase 2b: Recipe Precision Analysis (using diff artifacts)
log "Phase 2b: Analyzing recipe precision..."

RESULT_DIR="$OUTPUT_DIR/result"
PR_DIFF="$RESULT_DIR/pr.diff"
RECIPE_DIFF="$RESULT_DIR/recommended-recipe.diff"

if [[ -f "$PR_DIFF" && -f "$RECIPE_DIFF" ]]; then
    log "  Found PR diff and recipe diff, calculating precision..."

    PRECISION_OUTPUT="$OUTPUT_DIR/recipe-precision-analysis.json"

    if "$PLUGIN_DIR/scripts/analysis/recipe-diff-precision.sh" "$PR_DIFF" "$RECIPE_DIFF" "$PRECISION_OUTPUT"; then
        log "  Recipe precision stats saved to: $PRECISION_OUTPUT"

        # Display key metrics from the new script output
        precision=$(jq -r '.metrics.precision' "$PRECISION_OUTPUT")
        recall=$(jq -r '.metrics.recall' "$PRECISION_OUTPUT")
        f1_score=$(jq -r '.metrics.f1_score' "$PRECISION_OUTPUT")
        is_perfect=$(jq -r '.metrics.is_perfect_match' "$PRECISION_OUTPUT")

        log "    Precision: $precision"
        log "    Recall: $recall"
        log "    F1 Score: $f1_score"
        log "    Perfect match: $is_perfect"
    else
        log "  Warning: Recipe precision analysis failed"
    fi
else
    log "  Diff files for precision analysis not found in: $RESULT_DIR"
    log "  Skipping precision analysis."
fi

if [[ "$SESSION_FETCH_FAILED" == "false" ]]; then
    log "  - Session log: $OUTPUT_DIR/claude-log.jsonl"
    log "  - Usage stats: $OUTPUT_DIR/claude-usage-stats.json"
    log "  - Cost stats: $OUTPUT_DIR/claude-cost-stats.json"
fi

if [[ -f "$OUTPUT_DIR/recipe-precision-stats.json" ]]; then
    log "  - Recipe precision: $OUTPUT_DIR/recipe-precision-stats.json"
fi
