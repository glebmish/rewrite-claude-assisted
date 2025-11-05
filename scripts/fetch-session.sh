#!/bin/bash

set -euxo pipefail

# Initialize variables
SCRATCHPAD_FILE=""
SESSION_ID=""
UUID=""
OUTPUT_FILE=""

# Function to show usage
usage() {
    echo "Usage: $0 [-f <filepath-to-scratchpad>] [-s <session-id>] [-o <output-file>]"
    echo "  -f: Extract session ID from scratchpad file"
    echo "  -s: Use provided session ID directly"
    echo "  -o: Specify output file path for the session log"
    echo "Examples:"
    echo "  $0 -f /path/to/scratchpad.md"
    echo "  $0 -s 0ab55372-1fc8-4700-975c-c1c770076a0f"
    echo "  $0 -s 0ab55372-1fc8-4700-975c-c1c770076a0f -o /path/to/output.jsonl"
    exit 1
}

# Parse command line arguments
while getopts "f:s:o:h" opt; do
    case $opt in
        f)
            SCRATCHPAD_FILE="$OPTARG"
            ;;
        s)
            SESSION_ID="$OPTARG"
            ;;
        o)
            OUTPUT_FILE="$OPTARG"
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

# Discover agent logs in same directory
echo "Discovering agent logs in: $SESSION_DIR"
AGENT_FILES=$(find "$SESSION_DIR" -name "agent-*.jsonl" -type f 2>/dev/null || true)

if [ -n "$AGENT_FILES" ]; then
    AGENT_COUNT=$(echo "$AGENT_FILES" | wc -l)
    echo "Found $AGENT_COUNT agent log(s)"
else
    echo "No agent logs found"
fi

# Determine output directory and main log filename
if [ -n "$OUTPUT_FILE" ]; then
  # If output file specified, use its directory and basename
  OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
  MAIN_LOG_FILENAME="$(basename "$OUTPUT_FILE")"
else
  # Default: use scratchpad directory or .sessions
  OUTPUT_DIR="./.sessions"
  if [ -n "$SCRATCHPAD_FILE" ]; then
    OUTPUT_DIR=$(dirname "$SCRATCHPAD_FILE")
  fi
  MAIN_LOG_FILENAME="claude-log.jsonl"
fi

# Create log directory structure
LOG_DIR="$OUTPUT_DIR/log"
mkdir -p "$LOG_DIR"

# Copy main session log to log directory
MAIN_LOG_DEST="$LOG_DIR/$MAIN_LOG_FILENAME"
cp "$SESSION_FILE" "$MAIN_LOG_DEST"
echo "Main session log copied to: $MAIN_LOG_DEST"

# Copy all agent logs to log directory
if [ -n "$AGENT_FILES" ]; then
    echo "Copying agent logs to: $LOG_DIR"
    echo "$AGENT_FILES" | while IFS= read -r agent_file; do
        if [ -n "$agent_file" ]; then
            agent_filename=$(basename "$agent_file")
            cp "$agent_file" "$LOG_DIR/$agent_filename"
            echo "  Copied: $agent_filename"
        fi
    done
else
    echo "No agent logs to copy"
fi

# Create backward-compatible symlink at old location
COMPAT_SYMLINK="$OUTPUT_DIR/claude-log.jsonl"
if [ ! -e "$COMPAT_SYMLINK" ]; then
    ln -s "log/$MAIN_LOG_FILENAME" "$COMPAT_SYMLINK"
    echo "Created backward-compatible symlink: $COMPAT_SYMLINK -> log/$MAIN_LOG_FILENAME"
fi

# Log summary
echo ""
echo "Session logs copied successfully:"
echo "  Main log: $MAIN_LOG_DEST"
if [ -n "$AGENT_FILES" ]; then
    AGENT_COUNT=$(echo "$AGENT_FILES" | wc -l)
    echo "  Agent logs: $AGENT_COUNT file(s) in $LOG_DIR"
fi