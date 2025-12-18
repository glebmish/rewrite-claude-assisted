#!/bin/bash
# Recipe Diff Precision Analysis
# Wrapper script to analyze recipe effectiveness by comparing its output against an original PR diff.

set -euo pipefail

# Function to show usage
usage() {
    echo "Usage: $0 <pr-diff-path> <recipe-diff-path> <output-json-path>"
    echo "  pr-diff-path:       Path to the diff of the original PR against main"
    echo "  recipe-diff-path:   Path to the diff of the recipe output against main"
    echo "  output-json-path:   Path where the final JSON analysis report will be saved"
    exit 1
}

# Check arguments
if [[ $# -ne 3 ]]; then
    usage
fi

PR_DIFF_PATH="$1"
RECIPE_DIFF_PATH="$2"
OUTPUT_FILE="$3"

# Validate input files
if [[ ! -f "$PR_DIFF_PATH" ]]; then
    echo "Error: PR diff file not found: $PR_DIFF_PATH"
    exit 1
fi

if [[ ! -f "$RECIPE_DIFF_PATH" ]]; then
    echo "Error: Recipe diff file not found: $RECIPE_DIFF_PATH"
    exit 1
fi

echo "Analyzing recipe precision using the new Python engine..."

# Get the directory where the script is located to find the python script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PYTHON_SCRIPT_PATH="$SCRIPT_DIR/analyze_diffs.py"

if [[ ! -f "$PYTHON_SCRIPT_PATH" ]]; then
    echo "Error: Python analysis script not found at: $PYTHON_SCRIPT_PATH"
    exit 1
fi

# Run the Python analysis script
# The python script will output JSON to stdout
analysis_json=$(python3 "$PYTHON_SCRIPT_PATH" "$PR_DIFF_PATH" "$RECIPE_DIFF_PATH")

# Check if the python script produced any output
if [[ -z "$analysis_json" ]]; then
    echo "Error: Python script produced no output."
    exit 1
fi

# Inject the timestamp and save the final report
echo "$analysis_json" | jq --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.analysis_timestamp = $timestamp' > "$OUTPUT_FILE"

echo "Recipe precision analysis saved to: $OUTPUT_FILE"