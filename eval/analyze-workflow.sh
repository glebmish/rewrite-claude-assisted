#!/bin/bash
set -euox pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Source shared settings parser
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/parse-settings.sh"

# Parse settings file for tool restrictions
SETTINGS_FILE="${SETTINGS_FILE:-$SCRIPT_DIR/settings.json}"
log "Parsing settings file: $SETTINGS_FILE"
parse_settings_file "$SETTINGS_FILE"

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
    log "Error: Failed to fetch session log"
    exit 1
fi

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

# Build Claude command with tool restrictions
CLAUDE_FLAGS=$(build_claude_flags)
CLAUDE_CMD="claude --model claude-haiku-4-5 $CLAUDE_FLAGS -p \"/analyze-session $SCRATCHPAD_FILE $SESSION_LOG\""

log "  Running: $CLAUDE_CMD"

ANALYSIS_OUTPUT_LOG="$SCRATCHPAD_DIR/analysis-output.log"
if timeout 10m bash -c "$CLAUDE_CMD" 2>&1 | tee "$ANALYSIS_OUTPUT_LOG"; then
    # Check for session limit
    if grep -qi "session limit reached" "$ANALYSIS_OUTPUT_LOG"; then
        log "Warning: Session limit reached during qualitative analysis"
    else
        log "Qualitative analysis complete"
    fi
else
    EXIT_CODE=$?
    # Check for session limit
    if grep -qi "session limit reached" "$ANALYSIS_OUTPUT_LOG"; then
        log "Warning: Session limit reached during qualitative analysis"
    elif [ $EXIT_CODE -eq 124 ]; then
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
