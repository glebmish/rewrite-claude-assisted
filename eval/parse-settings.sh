#!/bin/bash
# Shared settings file parser for Claude tool permissions
#
# This script provides functions to parse settings.json and apply
# tool restrictions to Claude commands.

# Parse settings file and export Claude tool flags
# Usage: parse_settings_file <settings-file-path>
# Exports: CLAUDE_ALLOWED_TOOLS, CLAUDE_DISALLOWED_TOOLS
parse_settings_file() {
    local settings_file="$1"
    local allowed_tools=""
    local disallowed_tools=""

    if [[ ! -f "$settings_file" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Warning: Settings file not found at $settings_file, skipping tool restrictions" >&2
        return 0
    fi

    if ! command -v jq &> /dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Warning: jq not available, skipping tool restrictions" >&2
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

    if [[ -n "$allowed_tools" ]] || [[ -n "$disallowed_tools" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tool restrictions loaded from settings" >&2
    fi
}

# Helper function to build Claude command flags with tool restrictions
# Usage: build_claude_flags
# Returns: string with --allowedTools and --disallowedTools flags
build_claude_flags() {
    local flags=""

    if [[ -n "${CLAUDE_ALLOWED_TOOLS:-}" ]]; then
        flags="$flags --allowedTools \"$CLAUDE_ALLOWED_TOOLS\""
    fi

    if [[ -n "${CLAUDE_DISALLOWED_TOOLS:-}" ]]; then
        flags="$flags --disallowedTools \"$CLAUDE_DISALLOWED_TOOLS\""
    fi

    echo "$flags"
}
