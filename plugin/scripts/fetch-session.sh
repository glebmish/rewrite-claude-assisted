#!/bin/bash

set -euo pipefail

# Initialize variables
SESSION_ID=""
OUTPUT_DIR=""

# Function to show usage
usage() {
    echo "Usage: $0 -s <session-id> -o <output-dir>"
    echo "  -s: Specify session id"
    echo "  -o: Specify output directory path for the session logs"
    echo "Examples:"
    echo "  $0 -s 0ab55372-1fc8-4700-975c-c1c770076a0f -o /path/to/logs"
    exit 1
}

# Parse command line arguments
while getopts "s:o:h" opt; do
    case $opt in
        s)
            SESSION_ID="$OPTARG"
            ;;
        o)
            OUTPUT_DIR="$OPTARG"
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

if [[ -z "$SESSION_ID" ]]; then
    echo "Error: Must provide -s option"
    usage
fi

# Handle session ID input
if [ -n "$SESSION_ID" ]; then
    # Validate session ID format
    if [[ ! "$SESSION_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        echo "Error: Invalid session ID format. Expected UUID format."
        exit 1
    fi

    echo "Using session ID: $SESSION_ID"
fi

if [ -z "$OUTPUT_DIR" ]; then
  echo "Error: Must provide -o option"
  usage
fi

mkdir -p "$OUTPUT_DIR"

# Function to check if an agent log is a system agent
# We assume it's a system agent if it has just 1 log line (no interactions)
is_system_agent() {
    local agent_file="$1"

    if [[ $(cat "$agent_file" || wc -l) == 1 ]]; then
        return 0  # true - is system agent
    else
        return 1  # false - not system agent
    fi
}

# Get current project directory name
CURRENT_PROJECT_DIR=$(basename "$(pwd)")
echo "Current project directory: $CURRENT_PROJECT_DIR"

# Search for <id>.jsonl recursively in ~/.claude/projects
SESSION_FILE=$(find ~/.claude/projects -name "${SESSION_ID}.jsonl" -type f 2>/dev/null)

if [ -z "$SESSION_FILE" ]; then
    echo "Error: Session file '${SESSION_ID}.jsonl' not found in ~/.claude/projects"
    exit 1
fi

echo "Found session file: $SESSION_FILE"

# Validate that the file belongs to current project
# Check if the directory containing the file ends with current project directory name
SESSION_DIR=$(dirname "$SESSION_FILE")
if [[ ! "$SESSION_DIR" == *"$CURRENT_PROJECT_DIR" ]]; then
    echo "Error: Session file does not belong to current project '$CURRENT_PROJECT_DIR'"
    echo "Found in: $SESSION_DIR"
    exit 1
fi

echo "Session file validated for project: $CURRENT_PROJECT_DIR"

# Discover agent logs in same directory
echo "Discovering agent logs in: $SESSION_DIR"
AGENT_FILES=$(find "$SESSION_DIR" -name "agent-*.jsonl" -type f 2>/dev/null || true)

if [ -n "$AGENT_FILES" ]; then
    AGENT_COUNT=$(echo "$AGENT_FILES" | wc -l)
    echo "Found $AGENT_COUNT agent log(s)"
else
    echo "No agent logs found"
fi

cp "$SESSION_FILE" "$OUTPUT_DIR"
echo "Main session log copied to: $OUTPUT_DIR"

# Copy all agent logs to log directory (excluding warmup agents)
if [ -n "$AGENT_FILES" ]; then
    echo "Copying agent logs to: $OUTPUT_DIR"
    COPIED_COUNT=0
    SKIPPED_COUNT=0
    echo "$AGENT_FILES" | while IFS= read -r agent_file; do
        if [ -n "$agent_file" ]; then
            if is_system_agent "$agent_file"; then
                echo "  Skipping warmup agent: $(basename "$agent_file")"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            else
                cp "$agent_file" "$OUTPUT_DIR"
                COPIED_COUNT=$((COPIED_COUNT + 1))
            fi
        fi
    done
    echo "Agent logs copied: $COPIED_COUNT, skipped warmup agents: $SKIPPED_COUNT"
else
    echo "No agent logs to copy"
fi