#!/bin/bash
set -euox pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

# Source shared settings parser
#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#source "$SCRIPT_DIR/parse-settings.sh"

# Parse settings file for tool restrictions
#SETTINGS_FILE="${SETTINGS_FILE:-$SCRIPT_DIR/settings.json}"
#log "Parsing settings file: $SETTINGS_FILE"
#parse_settings_file "$SETTINGS_FILE"

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
if ! scripts/fetch-session.sh -s "$SESSION_ID" -o "$LOG_DIR"; then
    log "Error: Failed to fetch session log"
    exit 1
fi
log "Session log saved to: $SESSION_LOG"
SESSION_FETCH_FAILED=false

# Phase 2: Quantitative analysis (combined usage and cost stats)
log "Phase 2: Running quantitative analysis..."

log "  Running usage and cost stats analysis..."
if scripts/analysis/claude-stats.py "$SESSION_LOG" -o "$OUTPUT_DIR"; then
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

    if scripts/analysis/recipe-diff-precision.sh "$PR_DIFF" "$RECIPE_DIFF" "$PRECISION_OUTPUT"; then
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

# Phase 3: Qualitative analysis (exact prompt from workflow)
#log "Phase 3: Running qualitative analysis with Claude..."
#
# Build Claude command with tool restrictions
#CLAUDE_FLAGS=$(build_claude_flags)
#CLAUDE_CMD="claude --model claude-sonnet-4-5 $CLAUDE_FLAGS -p \"/analyze-session $OUTPUT_DIR $SESSION_LOG\""
#
#log "  Running: $CLAUDE_CMD"
#
#ANALYSIS_OUTPUT_LOG="$OUTPUT_DIR/analysis-output.log"
#if timeout 10m bash -c "$CLAUDE_CMD" 2>&1 | tee "$ANALYSIS_OUTPUT_LOG"; then
#    # Check for session limit
#    if grep -qi "session limit reached" "$ANALYSIS_OUTPUT_LOG"; then
#        log "Warning: Session limit reached during qualitative analysis"
#    else
#        log "Qualitative analysis complete"
#    fi
#else
#    EXIT_CODE=$?
#    Check for session limit
#    if grep -qi "session limit reached" "$ANALYSIS_OUTPUT_LOG"; then
#        log "Warning: Session limit reached during qualitative analysis"
#    elif [ $EXIT_CODE -eq 124 ]; then
#        log "Warning: Qualitative analysis timed out after 10 minutes"
#    else
#        log "Warning: Qualitative analysis failed with exit code $EXIT_CODE"
#    fi
#fi
#
#log "Analysis workflow complete"
#log "Results available in: $OUTPUT_DIR"

if [[ "$SESSION_FETCH_FAILED" == "false" ]]; then
    log "  - Session log: $OUTPUT_DIR/claude-log.jsonl"
    log "  - Usage stats: $OUTPUT_DIR/claude-usage-stats.json"
    log "  - Cost stats: $OUTPUT_DIR/claude-cost-stats.json"
fi

if [[ -f "$OUTPUT_DIR/recipe-precision-stats.json" ]]; then
    log "  - Recipe precision: $OUTPUT_DIR/recipe-precision-stats.json"
fi

#if [[ -f "$OUTPUT_DIR/evaluation-report.md" ]]; then
#  cat "$OUTPUT_DIR/evaluation-report.md" >> $GITHUB_STEP_SUMMARY
#fi
