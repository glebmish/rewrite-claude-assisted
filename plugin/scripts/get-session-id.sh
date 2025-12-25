#!/bin/bash

# Get current directory name
current_dir=$(basename "$(pwd)")

# Function to show usage
usage() {
    echo "Usage: $0 [-o <output-file>]"
    echo "  -o: Optional. Path to a file where the session ID will be written."
    echo "      If not provided, the session ID is printed to stdout."
    exit 1
}

OUTPUT_FILE=""

# Parse command line arguments
while getopts "o:h" opt; do
    case $opt in
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

# Find the most recently updated .jsonl file for this project
latest_file=$(find ~/.claude/projects -wholename "*${current_dir}/*.jsonl" -exec stat -c '%y %n' {} + | sort -r | head -1 | cut -d' ' -f4-)

# Extract filename without path and extension
if [ -n "$latest_file" ]; then
    session_id=$(basename "$latest_file" .jsonl)

    if [ -n "$OUTPUT_FILE" ]; then
        echo "$session_id" > "$OUTPUT_FILE"
        echo "Session ID written to: $OUTPUT_FILE" >&2
    else
        echo "$session_id"
    fi
else
    echo "No session files found for project: $current_dir" >&2
    exit 1
fi