#!/usr/bin/env bash
set -euo pipefail

# Script: 00-init-database.sh
# Purpose: Initialize PostgreSQL database and apply schema

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
PROJECT_DIR="$SCRIPT_DIR/.."

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

# Parse command line arguments
RESET_DB=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --reset)
            RESET_DB=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--reset]"
            echo "  --reset: Drop and recreate the database schema"
            exit 1
            ;;
    esac
done

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Database configuration with defaults
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-openrewrite_recipes}"
DB_USER="${DB_USER:-mcp_user}"
DB_PASSWORD="${DB_PASSWORD:-changeme}"
POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-openrewrite-postgres}"

# Schema files location
SCHEMA_DIR="$PROJECT_DIR/db-init"

echo "========================================="
echo "Stage 0: Initialize Database"
echo "========================================="

# Verify schema directory exists
if [ ! -d "$SCHEMA_DIR" ]; then
    log_error "Schema directory not found: $SCHEMA_DIR"
    exit 1
fi

# Verify schema files exist
if [ ! -f "$SCHEMA_DIR/01-create-extensions.sql" ]; then
    log_error "Schema file not found: $SCHEMA_DIR/01-create-extensions.sql"
    exit 1
fi

if [ ! -f "$SCHEMA_DIR/02-create-schema.sql" ]; then
    log_error "Schema file not found: $SCHEMA_DIR/02-create-schema.sql"
    exit 1
fi

log_success "Schema files found"

# Start PostgreSQL container
log_info "Starting PostgreSQL container..."
cd "$PROJECT_DIR"

if docker-compose up -d postgres; then
    log_success "PostgreSQL container started"
else
    log_error "Failed to start PostgreSQL container"
    exit 1
fi

# Wait for database to be ready
log_info "Waiting for database to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker-compose exec -T postgres pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
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

# Check if database is already initialized
log_info "Checking if database is already initialized..."
TABLE_EXISTS=$(docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc \
    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'recipes');" 2>/dev/null || echo "false")

if [ "$TABLE_EXISTS" = "t" ]; then
    if [ "$RESET_DB" = false ]; then
        log_error "Database is already initialized (recipes table exists)"
        log_error "Use --reset flag to drop and recreate the schema"
        exit 1
    else
        log_warning "Database is already initialized - dropping schema due to --reset flag"

        # Drop all tables
        log_info "Dropping existing tables..."
        docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" <<-EOSQL
			DROP TABLE IF EXISTS recipe_embeddings CASCADE;
			DROP TABLE IF EXISTS recipes CASCADE;
		EOSQL
        log_success "Existing tables dropped"
    fi
else
    log_success "Database is not initialized - proceeding with schema creation"
fi

# Apply schema files
log_info "Applying schema files..."

# Apply 01-create-extensions.sql
log_info "Creating extensions..."
if docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" < "$SCHEMA_DIR/01-create-extensions.sql" >/dev/null 2>&1; then
    log_success "Extensions created"
else
    log_error "Failed to create extensions"
    exit 1
fi

# Apply 02-create-schema.sql
log_info "Creating schema..."
if docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" < "$SCHEMA_DIR/02-create-schema.sql" >/dev/null 2>&1; then
    log_success "Schema created"
else
    log_error "Failed to create schema"
    exit 1
fi

# Verify schema was applied
log_info "Verifying schema..."
RECIPE_TABLE_EXISTS=$(docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc \
    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'recipes');" 2>/dev/null || echo "false")

EMBEDDINGS_TABLE_EXISTS=$(docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc \
    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'recipe_embeddings');" 2>/dev/null || echo "false")

if [ "$RECIPE_TABLE_EXISTS" = "t" ] && [ "$EMBEDDINGS_TABLE_EXISTS" = "t" ]; then
    log_success "Schema verification passed"
else
    log_error "Schema verification failed"
    log_error "recipes table exists: $RECIPE_TABLE_EXISTS"
    log_error "recipe_embeddings table exists: $EMBEDDINGS_TABLE_EXISTS"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Stage 0 Complete"
echo "========================================="
log_success "Database initialized successfully"
log_info "Database is ready for data ingestion"
echo ""
echo "Next step: Run 01-setup-generator.sh"
echo ""
