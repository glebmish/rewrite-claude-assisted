#!/usr/bin/env bash
set -euo pipefail

# Script: setup.sh
# Purpose: One-time setup to prepare the MCP server environment
# - Pull or build the pre-loaded database image
# - Create Python virtual environment
# - Install dependencies
# - Verify Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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
echo "║  OpenRewrite MCP Server Setup                              ║"
echo "║  One-time initialization                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
    log_info "Loaded configuration from .env"
else
    if [ -f "$PROJECT_DIR/.env.example" ]; then
        log_info "Creating .env from .env.example"
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        set -a
        source "$PROJECT_DIR/.env"
        set +a
        log_success ".env created"
    else
        log_warning "No .env file found, using defaults"
    fi
fi

# Configuration with defaults
DB_IMAGE_NAME="${DB_IMAGE_NAME}"
DB_IMAGE_TAG="${DB_IMAGE_TAG}"
FULL_IMAGE_NAME="${DB_IMAGE_NAME}:${DB_IMAGE_TAG}"

echo "Configuration:"
echo "  Database image: $FULL_IMAGE_NAME"
echo ""

# Step 1: Verify Docker
log_info "Step 1/5: Verifying Docker installation..."
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    echo "  Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running"
    echo "  Please start Docker and try again"
    exit 1
fi

log_success "Docker verified: $(docker --version)"

# Step 2: Verify docker-compose
log_info "Step 2/5: Verifying docker-compose..."
if ! command -v docker-compose &> /dev/null; then
    log_error "docker-compose is not installed"
    echo "  Please install docker-compose: https://docs.docker.com/compose/install/"
    exit 1
fi

log_success "docker-compose verified: $(docker-compose --version)"

# Step 3: Prepare database image
log_info "Step 3/5: Preparing pre-loaded database image..."

# Check if image exists locally
if docker image inspect "$FULL_IMAGE_NAME" &> /dev/null; then
    log_success "Image already exists locally: $FULL_IMAGE_NAME"

    # Show image info
    IMAGE_SIZE=$(docker images "$FULL_IMAGE_NAME" --format "{{.Size}}")
    IMAGE_CREATED=$(docker images "$FULL_IMAGE_NAME" --format "{{.CreatedAt}}")
    echo "  Size: $IMAGE_SIZE"
    echo "  Created: $IMAGE_CREATED"
else
    log_warning "Image not found locally: $FULL_IMAGE_NAME"

    log_info "Attempting to pull from registry..."
    if docker pull "$FULL_IMAGE_NAME"; then
        log_success "Image pulled successfully"
    else
        log_error "Failed to pull image from registry"
        echo ""
        echo "Build the image locally:"
        echo "  cd ../data-ingestion"
        echo "  ./scripts/run-full-pipeline.sh"
        echo ""
        exit 1
    fi
fi

# Step 4: Setup Python environment
log_info "Step 4/5: Setting up Python environment..."

if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed"
    echo "  Please install Python 3.8 or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
log_success "Python verified: $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [ ! -d "$PROJECT_DIR/venv" ]; then
    log_info "Creating Python virtual environment..."
    python3 -m venv "$PROJECT_DIR/venv"
    log_success "Virtual environment created"
else
    log_success "Virtual environment already exists"
fi

# Install dependencies
log_info "Installing Python dependencies..."
source "$PROJECT_DIR/venv/bin/activate"
pip install -q --upgrade pip
pip install -q -r "$PROJECT_DIR/requirements.txt"
deactivate
log_success "Dependencies installed"

# Step 5: Verify setup
log_info "Step 5/5: Verifying setup..."

# Check all required files exist
REQUIRED_FILES=(
    "$PROJECT_DIR/src/server.py"
    "$PROJECT_DIR/requirements.txt"
    "$PROJECT_DIR/docker-compose.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "Required file missing: $file"
        exit 1
    fi
done

log_success "All required files present"

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Setup Complete!                                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_success "MCP server is ready to run"
echo ""
echo "Configuration:"
echo "  Database: $FULL_IMAGE_NAME"
echo "  Python: $PYTHON_VERSION"
echo ""
echo "Next steps:"
echo ""
echo "  1. Start the server:"
echo "     ./scripts/startup.sh"
echo ""
echo "  2. To update recipe data (change image version):"
echo "     - Rebuild image: cd ../data-ingestion && ./scripts/run-full-pipeline.sh"
echo "     - Update .env: DB_IMAGE_TAG=<new-date>"
echo "     - Restart server"
echo ""
echo "  3. Configure Claude Code:"
echo "     See README.md for .mcp.json configuration"
echo ""
