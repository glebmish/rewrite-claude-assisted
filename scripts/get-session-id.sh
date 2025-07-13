#!/bin/bash

# Get current directory name
current_dir=$(basename "$(pwd)")

# Find the most recently updated .jsonl file for this project
latest_file=$(find ~/.claude/projects -wholename "*${current_dir}/*.jsonl" -exec stat -c '%y %n' {} + | sort -r | head -1 | cut -d' ' -f4-)

# Extract filename without path and extension
if [ -n "$latest_file" ]; then
    session_id=$(basename "$latest_file" .jsonl)
    echo "$session_id"
else
    echo "No session files found for project: $current_dir" >&2
    exit 1
fi