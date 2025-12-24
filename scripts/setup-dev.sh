#!/usr/bin/env bash
# Script: setup-dev.sh
# Purpose: Setup development environment for rewrite-claude-assisted repo
# Usage: ./scripts/setup-dev.sh [--skip-prerequisites-check]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MCP_DIR="$PROJECT_ROOT/plugin/mcp-server"

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

# Step 1: Check prerequisites
if [ "$SKIP_PREREQUISITES" = false ]; then
    log_info "Step 1/5: Checking prerequisites..."
    echo ""

    if [ -x "$SCRIPT_DIR/check-dev-prerequisites.sh" ]; then
        if "$SCRIPT_DIR/check-dev-prerequisites.sh"; then
            echo ""
        else
            log_error "Prerequisites check failed"
            echo ""
            echo "Please install missing prerequisites and run this script again."
            exit 1
        fi
    else
        log_warning "check-dev-prerequisites.sh not found or not executable, skipping validation"
    fi
else
    log_info "Step 1/5: Skipping prerequisites check..."
    echo ""
fi

# Step 2: Setup Python environment with venv
log_info "Step 2/5: Setting up Python environment..."
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

# Create virtual environment with venv
log_info "Creating virtual environment..."
python3 -m venv venv
log_success "Virtual environment created"

# Install dependencies with pip
log_info "Installing Python dependencies..."
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt
log_success "Dependencies installed"

cd "$PROJECT_ROOT"

# Step 3: Pull Docker image (don't start)
log_info "Step 3/5: Pulling Docker image..."
echo ""

FULL_IMAGE_NAME="${DB_IMAGE_NAME:-glebmish/openrewrite-recipes-db}:${DB_IMAGE_TAG:-latest}"

if docker image inspect "$FULL_IMAGE_NAME" &> /dev/null; then
    log_success "Docker image already exists: $FULL_IMAGE_NAME"
else
    log_info "Pulling image: $FULL_IMAGE_NAME"
    if docker pull "$FULL_IMAGE_NAME"; then
        log_success "Docker image pulled successfully"
    else
        log_error "Failed to pull Docker image"
        echo "   Try manually: docker pull $FULL_IMAGE_NAME"
        exit 1
    fi
fi

# Step 4: Configure MCP
log_info "Step 4/5: Configuring MCP..."
echo ""

# Generate local .mcp.json for development
if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
    log_success "MCP configuration already exists"
else
    cat > "$PROJECT_ROOT/.mcp.json" << EOF
{
  "mcpServers": {
    "openrewrite-mcp": {
      "type": "stdio",
      "command": "$MCP_DIR/scripts/startup.sh",
      "args": [],
      "env": {}
    }
  }
}
EOF
    log_success "MCP configuration created at .mcp.json"
fi

# Step 5: Verify eval framework
log_info "Step 5/5: Verifying eval framework..."
echo ""

if [ -f "$PROJECT_ROOT/eval/entrypoint.sh" ] && [ -d "$PROJECT_ROOT/eval/suites" ]; then
    log_success "Evaluation framework present"
else
    log_warning "Evaluation framework incomplete (some files missing)"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✓ Development Setup Complete!                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_success "Development environment is configured"
echo ""
echo "Configuration:"
echo "  MCP Server: $MCP_DIR"
echo "  Docker Image: $FULL_IMAGE_NAME"
echo "  MCP Config: $PROJECT_ROOT/.mcp.json"
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
