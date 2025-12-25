#!/usr/bin/env bash
# Script: check-dev-prerequisites.sh
# Purpose: Validate development prerequisites for rewrite-claude-assisted repo
# Usage: ./scripts/check-dev-prerequisites.sh
#
# This script runs the plugin prerequisites check first, then adds dev-specific checks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$PROJECT_ROOT/plugin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DEV_FAILED_CHECKS=0
DEV_WARNING_CHECKS=0

log_check() {
    echo -e "${BLUE}➤${NC}  Checking $1..."
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
    ((DEV_FAILED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
    ((DEV_WARNING_CHECKS++))
}

# Step 1: Run plugin prerequisites check
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Development Prerequisites Check                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Running plugin prerequisites check first..."
echo ""

if ! "$PLUGIN_DIR/scripts/check-prerequisites.sh"; then
    echo ""
    log_error "Plugin prerequisites check failed"
    echo "Please fix the issues above and run this script again."
    exit 1
fi

# Step 2: Additional dev-specific checks
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Additional Development Checks                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Claude Code CLI (dev-specific)
log_check "Claude Code CLI"
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown version")
    log_success "Claude Code CLI installed: $CLAUDE_VERSION"
else
    log_warning "Claude Code CLI not found (needed for running workflows)"
    echo "   Install: npm install -g @anthropic-ai/claude-code"
fi

# 2. Disk space (stricter for dev - 5GB vs 2GB)
log_check "Disk space (5GB+ for development)"
AVAILABLE_GB=$(df -BG . | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$AVAILABLE_GB" -ge 5 ]; then
    log_success "Sufficient disk space: ${AVAILABLE_GB}GB available"
else
    log_warning "Low disk space: ${AVAILABLE_GB}GB available (5GB+ recommended for development)"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
if [ $DEV_FAILED_CHECKS -eq 0 ]; then
    if [ $DEV_WARNING_CHECKS -eq 0 ]; then
        echo "║  ✓ All Development Prerequisites Met!                     ║"
    else
        echo "║  ✓ Required Prerequisites Met (with warnings)             ║"
    fi
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "System ready for development setup"
    if [ $DEV_WARNING_CHECKS -gt 0 ]; then
        log_warning "$DEV_WARNING_CHECKS optional prerequisite(s) missing"
    fi
    echo ""
    exit 0
else
    echo "║  ✗ Development Prerequisites Check Failed                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_error "$DEV_FAILED_CHECKS required prerequisite(s) missing"
    if [ $DEV_WARNING_CHECKS -gt 0 ]; then
        log_warning "$DEV_WARNING_CHECKS optional prerequisite(s) missing"
    fi
    echo ""
    echo "Please install missing prerequisites and run this script again."
    echo ""
    exit 1
fi
