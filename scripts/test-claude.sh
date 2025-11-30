#!/usr/bin/env bash
# Script: test-claude.sh
# Purpose: Test Claude Code integration with MCP server
# Usage: ./scripts/test-claude.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_check() {
    echo -e "${BLUE}➤${NC}  Checking $1..."
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Claude Code MCP Integration Test                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Check Claude CLI installed
log_check "Claude Code CLI"
if ! command -v claude &> /dev/null; then
    log_error "Claude Code CLI not installed"
    echo ""
    echo "Please install Claude Code:"
    echo "  https://github.com/anthropics/claude-code"
    echo ""
    exit 1
fi
log_success "Claude Code CLI found"

# 2. Check .mcp.json configuration
log_check "MCP server configuration"
if [ ! -f "$PROJECT_ROOT/.mcp.json" ]; then
    log_error ".mcp.json not found"
    echo ""
    echo "Please run the setup to create .mcp.json:"
    echo "  ./scripts/quick-setup.sh"
    echo ""
    exit 1
fi

if ! grep -q "openrewrite-mcp" "$PROJECT_ROOT/.mcp.json"; then
    log_error "openrewrite-mcp not configured in .mcp.json"
    echo ""
    echo "Please run the setup script to generate .mcp.json:"
    echo "  ./scripts/quick-setup.sh"
    echo ""
    exit 1
fi
log_success "MCP server configured in .mcp.json"

# 3. Check settings.json permissions
log_check "MCP tool permissions"
if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
    if grep -q "mcp__openrewrite-mcp__test_connection" "$PROJECT_ROOT/.claude/settings.json"; then
        log_success "MCP tools permitted in settings"
    else
        log_error "MCP tools not permitted in settings.json"
        echo ""
        echo "Please add MCP tool permissions to .claude/settings.json"
        echo ""
        exit 1
    fi
fi

# 4. Test actual MCP connection with claude -p
log_check "MCP connection via Claude Code"

# Create test prompt that returns specific output
TEST_PROMPT="Use the mcp__openrewrite-mcp__test_connection tool with message 'setup-verification'. Return ONLY 'PASS: MCP connection successful' if the tool works, or 'FAIL: MCP connection failed' if it doesn't."

# Run claude in non-interactive mode
cd "$PROJECT_ROOT"
if CLAUDE_OUTPUT=$(claude -p "$TEST_PROMPT" 2>&1); then
    # Check for success indicator
    if echo "$CLAUDE_OUTPUT" | grep -qi "PASS.*MCP connection successful"; then
        log_success "Claude Code successfully connected to MCP server"
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║  ✓ All Checks Passed!                                     ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Claude Code is ready to use with MCP server"
        echo ""
        exit 0
    elif echo "$CLAUDE_OUTPUT" | grep -qi "FAIL.*MCP connection failed"; then
        log_error "Claude Code could not connect to MCP server"
        echo ""
        echo "Claude output:"
        echo "$CLAUDE_OUTPUT"
        echo ""
        exit 1
    else
        # Ambiguous output - check if tool was called
        if echo "$CLAUDE_OUTPUT" | grep -q "test_connection"; then
            log_success "MCP tool invoked successfully"
            echo ""
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║  ✓ All Checks Passed!                                     ║"
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Claude Code is ready to use with MCP server"
            echo ""
            exit 0
        else
            log_error "Could not verify MCP connection"
            echo ""
            echo "Claude output did not contain expected pass/fail indicator"
            echo "Output:"
            echo "$CLAUDE_OUTPUT"
            echo ""
            exit 1
        fi
    fi
else
    log_error "Failed to run Claude Code"
    echo ""
    echo "Error output:"
    echo "$CLAUDE_OUTPUT"
    echo ""
    exit 1
fi
