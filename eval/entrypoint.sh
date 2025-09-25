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
    sleep 15
    log "Starting background workflow monitor"

    # Find the earliest JSONL file in ~/.claude/projects and subdirectories
    local jsonl_file=$(find ~/.claude/projects -name "*.jsonl" -type f -printf '%T@ %p\n' | sort -n | head -1 | cut -d' ' -f2-)

    if [[ -z "$jsonl_file" ]]; then
      log "Warning: No JSONL files found in ~/.claude/projects"
    fi

    # Start background monitoring process
    (
        while true; do
            sleep 15
            tail -n 4 "$jsonl_file" | claude --model haiku -p "Summarize last few messages from a Claude Code session as one short sentence of 10-20 words in the form of 'this is finished', 'doing something else now', 'accessing something'. Be specific." 2>/dev/null || true
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
PR_URL=""
TIMEOUT_MINUTES=60
SETTINGS_FILE="$(dirname "$0")/settings.json"

while [[ $# -gt 0 ]]; do
    case $1 in
        --strict)
            STRICT_MODE=true
            shift
            ;;
        --settings-file)
            SETTINGS_FILE="$2"
            shift 2
            ;;
        *)
            if [[ -z "$PR_URL" ]]; then
                PR_URL="$1"
            else
                TIMEOUT_MINUTES="$1"
            fi
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

log "Setting up SSH key"
mkdir -p /root/.ssh
echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-keyscan github.com >> /root/.ssh/known_hosts
log "SSH key configured successfully"

# Export for use in scripts
export CLAUDE_CODE_OAUTH_TOKEN
export GH_TOKEN
export PR_URL
export TIMEOUT_MINUTES

# Parse settings file and generate Claude tool flags
parse_settings_file() {
    local settings_file="$1"
    local allowed_tools=""
    local disallowed_tools=""

    if [[ ! -f "$settings_file" ]]; then
        log "Warning: Settings file not found at $settings_file, skipping tool restrictions"
        return 0
    fi

    if ! command -v jq &> /dev/null; then
        log "Warning: jq not available, skipping tool restrictions"
        return 0
    fi

    # Extract allowed tools and convert to space-separated string
    if allowed_array=$(jq -r '.permissions.allow[]?' "$settings_file" 2>/dev/null); then
        allowed_tools=$(echo "$allowed_array" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    fi

    # Extract disallowed tools and convert to space-separated string  
    if disallowed_array=$(jq -r '.permissions.deny[]?' "$settings_file" 2>/dev/null); then
        disallowed_tools=$(echo "$disallowed_array" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    fi

    # Export for use in command building
    export CLAUDE_ALLOWED_TOOLS="$allowed_tools"
    export CLAUDE_DISALLOWED_TOOLS="$disallowed_tools"
}

# Initialize metadata
mkdir -p metadata
cat > metadata/execution-start.json << EOF
{
  "pr_url": "$PR_URL",
  "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "timeout_minutes": $TIMEOUT_MINUTES,
}
EOF

# Parse settings file to get tool restrictions
log "Parsing settings file: $SETTINGS_FILE"
parse_settings_file "$SETTINGS_FILE"

# Start workflow monitor
start_workflow_monitor

# Execute rewrite-assist command
log "Executing rewrite-assist command"
START_TIME=$(date +%s)

# Build the claude command
CLAUDE_CMD="claude"

# Add tool restrictions if available
if [[ -n "$CLAUDE_ALLOWED_TOOLS" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --allowedTools \"$CLAUDE_ALLOWED_TOOLS\""
fi
if [[ -n "$CLAUDE_DISALLOWED_TOOLS" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --disallowedTools \"$CLAUDE_DISALLOWED_TOOLS\""
fi

CLAUDE_CMD="$CLAUDE_CMD -p \"/rewrite-assist $PR_URL"
if [[ "$STRICT_MODE" == "true" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD. Give up IMMEDIATELY when something fails (tool access is not granted, tool use failed). Finish the conversation and explicitly state the reason you did. Print full tool name and command."
fi
CLAUDE_CMD="$CLAUDE_CMD\""

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

# Create final metadata
cat > metadata/execution-complete.json << EOF
{
  "pr_url": "$PR_URL",
  "status": "$EXECUTION_STATUS",
  "exit_code": $EXIT_CODE,
  "duration_seconds": $DURATION,
  "start_time": "$(date -d @$START_TIME -u +"%Y-%m-%dT%H:%M:%SZ")",
  "end_time": "$(date -d @$END_TIME -u +"%Y-%m-%dT%H:%M:%SZ")",
  "artifacts_collected": true
}
EOF

log "Evaluation complete"
exit $EXIT_CODE