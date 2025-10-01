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
  exit 1

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

log "  - Session log: $SCRATCHPAD_DIR/claude-log.jsonl"
log "  - Usage stats: $SCRATCHPAD_DIR/claude-usage-stats.json"
log "  - Cost stats: $SCRATCHPAD_DIR/claude-cost-stats.json"
