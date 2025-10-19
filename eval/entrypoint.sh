#!/bin/bash
set -euxo pipefail

# Set up cleanup trap
trap cleanup EXIT

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Background workflow monitoring
start_workflow_monitor() {
    log "Starting background workflow monitor"
    GITHUB_OUTPUT=${GITHUB_OUTPUT:-/dev/null}
    CLAUDE_LOG_CMD="claude --model claude-haiku-4-5"
    # Start background monitoring process
    (
        while [[ -z ${jsonl_file:-} ]]; do
            sleep 5
            # Find the earliest JSONL file in ~/.claude/projects and subdirectories
            jsonl_file=$(find ~/.claude/projects -name "*.jsonl" -type f -printf '%T@ %p\n' | sort -n | head -1 | cut -d' ' -f2- || echo "")
            echo "claude_log_file=$jsonl_file" >> $GITHUB_OUTPUT
        done

        while true; do
            sleep 30
            tail -n 4 "$jsonl_file" | $CLAUDE_LOG_CMD -p "Summarize last few messages from a Claude Code session as one short sentence of 10-20 words in the form of 'this is finished', 'doing something else now', 'accessing something'. Be specific." 2>/dev/null || true
        done
    ) &
    
    # Store PID for cleanup
    MONITOR_PID=$!
    export MONITOR_PID
    log "Workflow monitor started with PID: $MONITOR_PID"
}

# Cleanup function
cleanup() {
    if [[ -n "${MONITOR_PID:-}" ]]; then
        log "Stopping workflow monitor (PID: $MONITOR_PID)"
        kill $MONITOR_PID 2>/dev/null || true
        wait $MONITOR_PID 2>/dev/null || true
    fi
}

# Parse arguments
STRICT_MODE=false
DEBUG_MODE=false
PR_URL=""
TIMEOUT_MINUTES=60
SETTINGS_FILE="$(dirname "$0")/settings.json"

while [[ $# -gt 0 ]]; do
    case $1 in
        --strict)
            STRICT_MODE=true
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --timeout)
            TIMEOUT_MINUTES="$2"
            shift 2
            ;;
        --settings-file)
            SETTINGS_FILE="$2"
            shift 2
            ;;
        *)
            PR_URL="$1"
            shift
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PR_URL" ]]; then
    echo "Error: PR_URL is required"
    exit 1
fi

CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN}"
GH_TOKEN="${GH_TOKEN}"
SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY}"

# Export to make available for tools
export CLAUDE_CODE_OAUTH_TOKEN
export GH_TOKEN

pwd
tree -a .

log "Setting up SSH key"
mkdir -p /root/.ssh
echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-keyscan github.com >> /root/.ssh/known_hosts
log "SSH key configured successfully"

# Source shared settings parser
source "$(dirname "$0")/parse-settings.sh"

# Parse settings file to get tool restrictions
log "Parsing settings file: $SETTINGS_FILE"
parse_settings_file "$SETTINGS_FILE"

# Start workflow monitor
start_workflow_monitor

# Execute rewrite-assist command
log "Executing rewrite-assist command"
START_TIME=$(date +%s)

# Build the claude command
CLAUDE_CMD="claude --model claude-haiku-4-5"

# Add debug flag if enabled
if [[ "$DEBUG_MODE" == "true" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --debug"
fi

# Add tool restrictions if available
if [[ -n "$CLAUDE_ALLOWED_TOOLS" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --allowedTools \"$CLAUDE_ALLOWED_TOOLS\""
fi
if [[ -n "$CLAUDE_DISALLOWED_TOOLS" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --disallowedTools \"$CLAUDE_DISALLOWED_TOOLS\""
fi

CLAUDE_PROMPT="execute custom claude code command: read .claude/commands/rewrite-assist.md and execute the workflow precisely with the following input: $PR_URL."
if [[ "$STRICT_MODE" == "true" ]]; then
    CLAUDE_PROMPT="$CLAUDE_PROMPT Give up IMMEDIATELY when something fails (tool access is not granted, tool use failed). Finish the conversation and explicitly state the reason you did. Print full tool name and command."
fi
CLAUDE_CMD="$CLAUDE_CMD -p \"$CLAUDE_PROMPT\""

# Execute with timeout
if timeout "${TIMEOUT_MINUTES}m" bash -c "$CLAUDE_CMD"; then
    EXECUTION_STATUS="success"
    EXIT_CODE=0
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        EXECUTION_STATUS="timeout"
    else
        EXECUTION_STATUS="failed"
    fi
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

log "Execution completed with status: $EXECUTION_STATUS (duration: ${DURATION}s)"

SCRATCHPAD_DIR=$(ls -d -1 $PWD/.scratchpad/*)
echo "scratchpad_file=$SCRATCHPAD_DIR/rewrite-assist-scratchpad.md" >> $GITHUB_OUTPUT
echo "scratchpad_dir=$SCRATCHPAD_DIR" >> $GITHUB_OUTPUT

# Create final metadata
METADATA_FILE="$SCRATCHPAD_DIR/workflow-metadata.json"
cat > $METADATA_FILE << EOF
{
  "pr_url": "$PR_URL",
  "status": "$EXECUTION_STATUS",
  "exit_code": $EXIT_CODE,
  "duration_seconds": $DURATION,
  "start_time": "$(date -d @$START_TIME -u +"%Y-%m-%dT%H:%M:%SZ")",
  "end_time": "$(date -d @$END_TIME -u +"%Y-%m-%dT%H:%M:%SZ")",
}
EOF

log "Evaluation complete"
exit $EXIT_CODE
