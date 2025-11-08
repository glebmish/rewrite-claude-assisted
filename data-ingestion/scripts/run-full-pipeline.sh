#!/usr/bin/env bash
set -euo pipefail

# Script: run-full-pipeline.sh
# Purpose: Orchestrate the complete data ingestion pipeline

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

# Check if .env exists, if not copy from .env.example
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/.env.example" ]; then
        log_info "Creating .env from .env.example"
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        log_success ".env created - you may want to review and customize it"
    else
        log_warning "No .env file found, using defaults"
    fi
fi

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  OpenRewrite Recipe Data Ingestion Pipeline               ║"
echo "║  Full end-to-end execution                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Record start time
START_TIME=$(date +%s)

# Track which stages completed
STAGES_COMPLETED=()

# Stage 1: Setup Generator
echo ""
log_info "Stage 1/4: Setup Generator Repository"
echo "────────────────────────────────────────────────────────────"
if "$SCRIPT_DIR/01-setup-generator.sh"; then
    STAGES_COMPLETED+=("Stage 1: Setup")
    log_success "Stage 1 completed"
else
    log_error "Stage 1 failed"
    exit 1
fi

# Stage 2: Generate Documentation
echo ""
log_info "Stage 2/4: Generate Recipe Documentation"
echo "────────────────────────────────────────────────────────────"
log_warning "This stage may take 10-15 minutes on first run"
if "$SCRIPT_DIR/02-generate-docs.sh"; then
    STAGES_COMPLETED+=("Stage 2: Generate Docs")
    log_success "Stage 2 completed"
else
    log_error "Stage 2 failed"
    exit 1
fi

# Start PostgreSQL before Stage 3
echo ""
log_info "Starting PostgreSQL container..."
echo "────────────────────────────────────────────────────────────"
cd "$PROJECT_DIR"
if docker-compose up -d postgres; then
    log_success "PostgreSQL started"

    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    MAX_RETRIES=30
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if docker-compose exec -T postgres pg_isready -U "${DB_USER:-mcp_user}" -d "${DB_NAME:-openrewrite_recipes}" >/dev/null 2>&1; then
            log_success "Database is ready"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            log_error "Database failed to start after ${MAX_RETRIES} seconds"
            docker-compose logs postgres
            exit 1
        fi
        sleep 1
    done
else
    log_error "Failed to start PostgreSQL"
    exit 1
fi

# Stage 3: Ingest to Database
echo ""
log_info "Stage 3/4: Ingest Documentation to Database"
echo "────────────────────────────────────────────────────────────"

# Check if Python venv exists, if not create it
if [ ! -d "$PROJECT_DIR/venv" ]; then
    log_info "Creating Python virtual environment..."
    python3 -m venv "$PROJECT_DIR/venv"
    log_success "Virtual environment created"
fi

# Activate venv and install dependencies
log_info "Installing Python dependencies..."
source "$PROJECT_DIR/venv/bin/activate"
pip install -q -r "$PROJECT_DIR/requirements.txt"

if python3 "$SCRIPT_DIR/03-ingest-docs.py"; then
    STAGES_COMPLETED+=("Stage 3: Ingest Data")
    log_success "Stage 3 completed"
else
    log_error "Stage 3 failed"
    deactivate
    exit 1
fi

deactivate

# Stage 4: Create Docker Image
echo ""
log_info "Stage 4/4: Create Docker Image"
echo "────────────────────────────────────────────────────────────"
if "$SCRIPT_DIR/04-create-image.sh"; then
    STAGES_COMPLETED+=("Stage 4: Create Image")
    log_success "Stage 4 completed"
else
    log_error "Stage 4 failed"
    exit 1
fi

# Calculate execution time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Final summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Pipeline Completed Successfully!                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_success "All stages completed:"
for stage in "${STAGES_COMPLETED[@]}"; do
    echo "  ✓ $stage"
done
echo ""
log_info "Total execution time: ${MINUTES}m ${SECONDS}s"
echo ""
log_info "Next steps:"
echo "  1. Test the image:"
echo "     docker run -p 5432:5432 ${IMAGE_NAME:-openrewrite-recipes-db}:${IMAGE_TAG:-latest}"
echo ""
echo "  2. Use with MCP server:"
echo "     Update mcp-server/docker-compose.yml to use:"
echo "     image: ${IMAGE_NAME:-openrewrite-recipes-db}:${IMAGE_TAG:-latest}"
echo ""
echo "  3. Clean up temporary containers:"
echo "     docker-compose down"
echo ""
