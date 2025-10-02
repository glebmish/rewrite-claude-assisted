#!/bin/bash

set -euxo pipefail

# Initialize variables
SCRATCHPAD_FILE=""
SESSION_ID=""
UUID=""

# Function to show usage
usage() {
    echo "Usage: $0 [-f <filepath-to-scratchpad>] [-s <session-id>]"
    echo "  -f: Extract session ID from scratchpad file"
    echo "  -s: Use provided session ID directly"
    echo "Examples:"
    echo "  $0 -f /path/to/scratchpad.md"
    echo "  $0 -s 0ab55372-1fc8-4700-975c-c1c770076a0f"
    exit 1
}

# Parse command line arguments
while getopts "f:s:h" opt; do
    case $opt in
        f)
            SCRATCHPAD_FILE="$OPTARG"
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

# Check that exactly one option is provided
if [[ -n "$SCRATCHPAD_FILE" && -n "$SESSION_ID" ]]; then
    echo "Error: Cannot use both -f and -s options simultaneously"
    usage
fi

if [[ -z "$SCRATCHPAD_FILE" && -z "$SESSION_ID" ]]; then
    echo "Error: Must provide either -f or -s option"
    usage
fi

# Handle scratchpad file input
if [ -n "$SCRATCHPAD_FILE" ]; then
    # Check if scratchpad file exists
    if [ ! -f "$SCRATCHPAD_FILE" ]; then
        echo "Error: Scratchpad file '$SCRATCHPAD_FILE' not found"
        exit 1
    fi

    # Extract UUID from first line of scratchpad file
    UUID=$(head -n1 "$SCRATCHPAD_FILE" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')

    if [ -z "$UUID" ]; then
        echo "Error: No UUID found in first line of '$SCRATCHPAD_FILE'"
        exit 1
    fi

    echo "Found UUID: $UUID"
fi

# Handle session ID input
if [ -n "$SESSION_ID" ]; then
    # Validate session ID format
    if [[ ! "$SESSION_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        echo "Error: Invalid session ID format. Expected UUID format."
        exit 1
    fi
    
    UUID="$SESSION_ID"
    echo "Using session ID: $UUID"
fi

# Get current project directory name
CURRENT_PROJECT_DIR=$(basename "$(pwd)")
echo "Current project directory: $CURRENT_PROJECT_DIR"

# Search for <id>.jsonl recursively in ~/.claude/projects
SESSION_FILE=$(find ~/.claude/projects -name "${UUID}.jsonl" -type f 2>/dev/null)

if [ -z "$SESSION_FILE" ]; then
    echo "Error: Session file '${UUID}.jsonl' not found in ~/.claude/projects"
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

SESSION_DEST_DIR="./.sessions"
if [ -n "$SCRATCHPAD_FILE" ]; then
  SESSION_DEST_DIR=$(dirname "$SCRATCHPAD_FILE")
fi
mkdir -p "${SESSION_DEST_DIR}"

# Copy session file with determined name + .jsonl extension
DEST_FILE="$SESSION_DEST_DIR/claude-log.jsonl"
cp "$SESSION_FILE" "$DEST_FILE"

echo "Session file copied to: $DEST_FILE"

echo "Session file copied successfully."