#!/usr/bin/env bash
set -euo pipefail

# Script: rebuild-database.sh
# Purpose: Rebuild the pre-loaded database image with latest recipe data
# This is a convenience wrapper around the data-ingestion pipeline

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_INGESTION_DIR="$(cd "$PROJECT_DIR/../data-ingestion" && pwd)"

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
echo "║  Rebuild Pre-loaded Database Image                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if data-ingestion directory exists
if [ ! -d "$DATA_INGESTION_DIR" ]; then
    log_error "Data ingestion directory not found: $DATA_INGESTION_DIR"
    echo "  This script requires the data-ingestion pipeline"
    exit 1
fi

log_info "This will rebuild the database image with the latest OpenRewrite recipes"
echo ""
echo "Process:"
echo "  1. Clone/update recipe generator repository"
echo "  2. Generate markdown documentation (~1000+ recipes)"
echo "  3. Ingest recipes into PostgreSQL"
echo "  4. Commit container to Docker image"
echo ""
log_warning "This takes 15-20 minutes and requires ~2GB disk space"
echo ""

# Ask for confirmation
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

# Stop any running MCP server containers
log_info "Stopping any running MCP containers..."
cd "$PROJECT_DIR"
if docker-compose ps | grep -q "openrewrite-mcp-db"; then
    docker-compose down
    log_success "MCP containers stopped"
fi

# Run the data ingestion pipeline
log_info "Starting data ingestion pipeline..."
cd "$DATA_INGESTION_DIR"

if ./scripts/run-full-pipeline.sh; then
    log_success "Database image rebuilt successfully!"
    echo ""
    log_info "The new image is ready to use"
    echo ""
    echo "To use it:"
    echo "  1. Make sure DB_MODE=production in mcp-server/.env"
    echo "  2. Restart the MCP server: cd mcp-server && ./scripts/startup.sh"
    echo ""
    exit 0
else
    log_error "Failed to rebuild database image"
    echo "  Check the output above for errors"
    exit 1
fi
