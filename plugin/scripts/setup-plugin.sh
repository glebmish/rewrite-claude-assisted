#!/usr/bin/env bash
# Script: setup-plugin.sh
# Purpose: Setup MCP server environment for OpenRewrite Assist plugin
# Usage: ./scripts/setup-plugin.sh [--skip-prerequisites-check]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MCP_DIR="$PLUGIN_ROOT/mcp-server"

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
echo "║  OpenRewrite Assist Plugin - Setup                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check prerequisites
if [ "$SKIP_PREREQUISITES" = false ]; then
    log_info "Step 1/4: Checking prerequisites..."
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
else
    log_info "Step 1/4: Skipping prerequisites check..."
    echo ""
fi

# Step 2: Setup Python environment
log_info "Step 2/4: Setting up Python environment..."
echo ""

if [ ! -d "$MCP_DIR" ]; then
    log_error "MCP server directory not found: $MCP_DIR"
    exit 1
fi

cd "$MCP_DIR"

# Load environment variables
if [ -f ".env" ]; then
    set -a
    source ".env"
    set +a
    log_info "Loaded configuration from .env"
elif [ -f ".env.example" ]; then
    log_info "Creating .env from .env.example"
    cp ".env.example" ".env"
    set -a
    source ".env"
    set +a
    log_success ".env created"
else
    log_warning "No .env file found, using defaults"
    DB_IMAGE_NAME="glebmish/openrewrite-recipes-db"
    DB_IMAGE_TAG="latest"
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    log_info "Creating Python virtual environment..."
    python3 -m venv venv
    log_success "Virtual environment created"
else
    log_success "Virtual environment already exists"
fi

# Install dependencies
log_info "Installing Python dependencies..."
source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt
deactivate
log_success "Dependencies installed"

cd "$PLUGIN_ROOT"

# Step 3: Pull Docker image (always run - idempotent, updates if newer available)
log_info "Step 3/4: Pulling Docker image..."
echo ""

FULL_IMAGE_NAME="${DB_IMAGE_NAME}:${DB_IMAGE_TAG}"

log_info "Pulling image: $FULL_IMAGE_NAME"
if docker pull "$FULL_IMAGE_NAME"; then
    log_success "Docker image ready: $FULL_IMAGE_NAME"
else
    log_error "Failed to pull Docker image"
    echo "   Try manually: docker pull $FULL_IMAGE_NAME"
    exit 1
fi

# Step 4: Configure MCP
log_info "Step 4/4: Configuring MCP..."
echo ""

# Check if .mcp.json exists at plugin root
if [ -f "$PLUGIN_ROOT/.mcp.json" ]; then
    log_success "MCP configuration already exists"
else
    log_warning ".mcp.json not found at plugin root"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✓ Setup Complete!                                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_success "OpenRewrite Assist plugin is configured"
echo ""
echo "Configuration:"
echo "  MCP Server: $MCP_DIR"
echo "  Docker Image: $FULL_IMAGE_NAME"
echo ""
