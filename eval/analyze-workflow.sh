#!/bin/bash
set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Input validation
SCRATCHPAD_FILE="$1"
if [[ -z "$SCRATCHPAD_FILE" ]]; then
    echo "Error: scratchpad file required"
    echo "Usage: $0 <scratchpad-file>"
    exit 1
fi

if [[ ! -f "$SCRATCHPAD_FILE" ]]; then
    echo "Error: scratchpad file not found: $SCRATCHPAD_FILE"
    exit 1
fi

log "Starting analysis for: $SCRATCHPAD_FILE"
SCRATCHPAD_DIR="$(dirname $SCRATCHPAD_FILE)"

# Phase 1: Fetch session log
log "Phase 1: Fetching Claude session log..."

# Fetch session using existing script
if ! scripts/fetch-session.sh -f "$SCRATCHPAD_FILE"; then
    log "Warning: Failed to fetch session log, skipping quantitative analysis"
    SESSION_FETCH_FAILED=true
else
    SESSION_LOG="$SCRATCHPAD_DIR/claude-log.jsonl"
    log "Session log saved to: $SESSION_LOG"
    SESSION_FETCH_FAILED=false

    # Phase 2: Quantitative analysis (separate files)
    log "Phase 2: Running quantitative analysis..."

    log "  Running usage stats analysis..."
    if scripts/analysis/claude-usage-stats.sh "$SESSION_LOG"; then
        log "  Usage stats saved to: $SCRATCHPAD_DIR/claude-usage-stats.json"
    else
        log "  Warning: Usage stats analysis failed"
    fi

    log "  Running cost stats analysis..."
    if scripts/analysis/claude-cost-stats.sh "$SESSION_LOG"; then
        log "  Cost stats saved to: $SCRATCHPAD_DIR/claude-cost-stats.json"
    else
        log "  Warning: Cost stats analysis failed"
    fi

    log "Quantitative analysis complete"
fi

# Phase 2b: Recipe Precision Analysis (using diff artifacts)
log "Phase 2b: Analyzing recipe precision..."

RESULT_DIR="$SCRATCHPAD_DIR/result"
RECIPE_TO_PR_DIFF="$RESULT_DIR/recommended-recipe-to-pr.diff"

if [[ -f "$RECIPE_TO_PR_DIFF" ]]; then
    log "  Found recipe-to-PR diff, calculating precision..."

    PRECISION_OUTPUT="$SCRATCHPAD_DIR/recipe-precision-stats.json"

    if scripts/analysis/recipe-diff-precision.sh "$RECIPE_TO_PR_DIFF" "$PRECISION_OUTPUT"; then
        log "  Recipe precision stats saved to: $PRECISION_OUTPUT"

        # Display key metrics
        unnecessary=$(jq -r '.metrics.unnecessary_changes' "$PRECISION_OUTPUT")
        missing=$(jq -r '.metrics.missing_changes' "$PRECISION_OUTPUT")
        accuracy=$(jq -r '.metrics.accuracy' "$PRECISION_OUTPUT")
        is_perfect=$(jq -r '.metrics.is_perfect_match' "$PRECISION_OUTPUT")

        log "    Unnecessary changes: $unnecessary"
        log "    Missing changes: $missing"
        log "    Accuracy: $accuracy"
        log "    Perfect match: $is_perfect"
    else
        log "  Warning: Recipe precision analysis failed"
    fi
else
    log "  No recipe-to-PR diff found at: $RECIPE_TO_PR_DIFF"
    log "  Skipping precision analysis (workflow may not have completed Phase 5)"
fi

# Phase 3: Qualitative analysis (exact prompt from workflow)
log "Phase 3: Running qualitative analysis with Claude..."
if timeout 10m claude --model sonnet -p "/analyze-session $SCRATCHPAD_FILE $SESSION_LOG"; then
    log "Qualitative analysis complete"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        log "Warning: Qualitative analysis timed out after 10 minutes"
    else
        log "Warning: Qualitative analysis failed with exit code $EXIT_CODE"
    fi
fi

log "Analysis workflow complete"
log "Results available in: $SCRATCHPAD_DIR"

if [[ "$SESSION_FETCH_FAILED" == "false" ]]; then
    log "  - Session log: $SCRATCHPAD_DIR/claude-log.jsonl"
    log "  - Usage stats: $SCRATCHPAD_DIR/claude-usage-stats.json"
    log "  - Cost stats: $SCRATCHPAD_DIR/claude-cost-stats.json"
fi

if [[ -f "$SCRATCHPAD_DIR/recipe-precision-stats.json" ]]; then
    log "  - Recipe precision: $SCRATCHPAD_DIR/recipe-precision-stats.json"
fi
