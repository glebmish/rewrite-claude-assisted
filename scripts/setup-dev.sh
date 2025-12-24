#!/usr/bin/env bash
# Script: setup-dev.sh
# Purpose: Setup development environment for rewrite-claude-assisted repo
# Usage: ./scripts/setup-dev.sh [--skip-prerequisites-check]
#
# This script runs the plugin setup first, then adds dev-specific setup (data-ingestion).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$PROJECT_ROOT/plugin"
DATA_INGESTION_DIR="$PROJECT_ROOT/data-ingestion"

# Parse command-line flags
SKIP_PREREQUISITES=false

for arg in "$@"; do
    case $arg in
        --skip-prerequisites-check)
            SKIP_PREREQUISITES=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--skip-prerequisites-check]"
            exit 1
            ;;
    esac
done

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
echo "║  Development Environment Setup                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Run plugin setup
log_info "Step 1/2: Running plugin setup..."
echo ""

PLUGIN_SETUP_ARGS=""
if [ "$SKIP_PREREQUISITES" = true ]; then
    PLUGIN_SETUP_ARGS="--skip-prerequisites-check"
fi

if [ -x "$PLUGIN_DIR/scripts/setup-plugin.sh" ]; then
    if ! "$PLUGIN_DIR/scripts/setup-plugin.sh" $PLUGIN_SETUP_ARGS; then
        log_error "Plugin setup failed"
        exit 1
    fi
else
    log_error "Plugin setup-plugin.sh not found or not executable"
    exit 1
fi

# Step 2: Setup data-ingestion environment
echo ""
log_info "Step 2/2: Setting up data-ingestion environment..."
echo ""

if [ ! -d "$DATA_INGESTION_DIR" ]; then
    log_warning "data-ingestion directory not found, skipping"
else
    cd "$DATA_INGESTION_DIR"

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        log_info "Creating data-ingestion virtual environment..."
        python3 -m venv venv
        log_success "Virtual environment created"
    else
        log_success "Virtual environment already exists"
    fi

    # Install dependencies (always run - idempotent, catches updates)
    log_info "Installing data-ingestion dependencies..."
    source venv/bin/activate
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
    deactivate
    log_success "Dependencies installed"

    cd "$PROJECT_ROOT"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✓ Development Setup Complete!                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_success "Development environment is configured"
echo ""
echo "Next steps:"
echo ""
echo "  1. Start Claude Code and test the workflow:"
echo "     claude"
echo "     > /rewrite-assist https://github.com/owner/repo/pull/123"
echo ""
echo "  2. Run evaluations:"
echo "     See eval/README.md for instructions"
echo ""
