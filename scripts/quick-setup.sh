#!/usr/bin/env bash
# Script: quick-setup.sh
# Purpose: One-command setup for OpenRewrite Recipe Assistant
# Usage: ./scripts/quick-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  OpenRewrite Recipe Assistant - Quick Setup               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check prerequisites
log_info "Step 1/3: Checking prerequisites..."
echo ""

if [ -x "$SCRIPT_DIR/check-prerequisites.sh" ]; then
    if "$SCRIPT_DIR/check-prerequisites.sh"; then
        echo ""
    else
        log_error "Prerequisites check failed"
        echo ""
        echo "Please install missing prerequisites and run this script again."
        exit 1
    fi
else
    log_warning "check-prerequisites.sh not found or not executable, skipping validation"
fi

# Step 2: Setup MCP server
log_info "Step 2/3: Setting up MCP server..."
echo ""

if [ -x "$PROJECT_ROOT/mcp-server/scripts/setup.sh" ]; then
    cd "$PROJECT_ROOT/mcp-server"
    ./scripts/setup.sh
    cd "$PROJECT_ROOT"
else
    log_error "MCP server setup script not found: mcp-server/scripts/setup.sh"
    exit 1
fi

echo ""

# Step 2.5: Generate .mcp.json with correct path
log_info "Generating .mcp.json configuration..."
echo ""

cat > "$PROJECT_ROOT/.mcp.json" << EOF
{
  "mcpServers": {
    "openrewrite-mcp": {
      "type": "stdio",
      "command": "$PROJECT_ROOT/mcp-server/scripts/startup.sh",
      "args": [],
      "env": {}
    }
  }
}
EOF

if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
    log_success "Generated .mcp.json with path: $PROJECT_ROOT/mcp-server/scripts/startup.sh"
else
    log_error "Failed to generate .mcp.json"
    exit 1
fi

echo ""

# Step 3: Verify setup
log_info "Step 3/3: Verifying setup..."
echo ""

if [ -x "$SCRIPT_DIR/verify-setup.sh" ]; then
    # Run verification - it provides complete output including summary
    "$SCRIPT_DIR/verify-setup.sh" || true
    echo ""
else
    log_warning "verify-setup.sh not found, skipping verification"
fi

# Step 4: Test Claude Code integration (optional)
if [ "${1:-}" = "--test-claude" ]; then
    log_info "Step 4/4: Testing Claude Code integration..."
    echo ""

    if [ -x "$SCRIPT_DIR/test-claude.sh" ]; then
        if "$SCRIPT_DIR/test-claude.sh"; then
            echo ""
        else
            log_error "Claude Code integration test failed"
            exit 1
        fi
    else
        log_error "test-claude.sh not found or not executable"
        exit 1
    fi
fi

# Success summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✓ Setup Complete!                                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_success "OpenRewrite Recipe Assistant is ready to use"
echo ""
echo "Next steps:"
echo ""
echo "  1. Run an example workflow:"
echo "     claude"
echo "     > /rewrite-assist https://github.com/openrewrite-assist-testing-dataset/simple-blog-platform/pull/3"
echo ""
echo "  2. Or run non-interactively:"
echo "     claude --p \"/rewrite-assist https://github.com/openrewrite-assist-testing-dataset/simple-blog-platform/pull/3\""
echo ""
echo "See README.md for more information."
echo ""
