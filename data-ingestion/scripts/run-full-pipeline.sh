#!/usr/bin/env bash
set -euo pipefail

# Script: run-full-pipeline.sh
# Purpose: Orchestrate the complete data ingestion pipeline

# Load common utilities
COMMON_LIB="$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COMMON_LIB"

# Initialize script environment
init_script

# Check if .env exists, if not copy from .env.example
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/.env.example" ]; then
        log_info "Creating .env from .env.example"
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        log_success ".env created - you may want to review and customize it"
        # Reload environment variables
        set -a
        source "$PROJECT_DIR/.env"
        set +a
    else
        log_warning "No .env file found, using defaults"
    fi
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

# Stage 0: Initialize Database
echo ""
log_info "Stage 0/7: Initialize Database"
echo "────────────────────────────────────────────────────────────"
if "$SCRIPT_DIR/00-init-database.sh" --reset; then
    STAGES_COMPLETED+=("Stage 0: Initialize Database")
    log_success "Stage 0 completed"
else
    log_error "Stage 0 failed"
    exit 1
fi

# Stage 1: Setup Generator
echo ""
log_info "Stage 1/7: Setup Generator Repository"
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
log_info "Stage 2/7: Generate Recipe Documentation"
echo "────────────────────────────────────────────────────────────"
log_warning "This stage may take 10-15 minutes on first run"
if "$SCRIPT_DIR/02-generate-docs.sh"; then
    STAGES_COMPLETED+=("Stage 2: Generate Docs")
    log_success "Stage 2 completed"
else
    log_error "Stage 2 failed"
    exit 1
fi

# Stage 2b: Generate Structured Metadata (Phase 3)
echo ""
log_info "Stage 2b/7: Generate Structured Recipe Metadata"
echo "────────────────────────────────────────────────────────────"
if "$SCRIPT_DIR/02b-generate-structured-data.sh"; then
    STAGES_COMPLETED+=("Stage 2b: Generate Metadata")
    log_success "Stage 2b completed"
else
    log_error "Stage 2b failed"
    exit 1
fi

# Stage 3: Ingest to Database
echo ""
log_info "Stage 3/7: Ingest Documentation to Database"
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

# Stage 3b: Generate Embeddings (Phase 3)
echo ""
log_info "Stage 3b/7: Generate Recipe Embeddings"
echo "────────────────────────────────────────────────────────────"
log_warning "First run will download embedding model (~90MB)"

if python3 "$SCRIPT_DIR/03b-generate-embeddings.py"; then
    STAGES_COMPLETED+=("Stage 3b: Generate Embeddings")
    log_success "Stage 3b completed"
else
    log_error "Stage 3b failed"
    deactivate
    exit 1
fi

deactivate

# Stage 4: Create Docker Image
echo ""
log_info "Stage 4/7: Create Docker Image"
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
echo "     docker run -p 5432:5432 ${IMAGE_NAME:-bboygleb/openrewrite-recipes-db}:${IMAGE_TAG:-latest}"
echo ""
echo "  2. Use with MCP server:"
echo "     Update mcp-server/docker-compose.yml to use:"
echo "     image: ${IMAGE_NAME:-bboygleb/openrewrite-recipes-db}:${IMAGE_TAG:-latest}"
echo ""
echo "  3. Clean up temporary containers:"
echo "     docker-compose down"
echo ""
