#!/usr/bin/env bash
set -euo pipefail

# Script: 00-init-database.sh
# Purpose: Initialize PostgreSQL database and apply schema

# Load common utilities
COMMON_LIB="$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COMMON_LIB"

# Initialize script environment
init_script

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

# Setup database configuration
setup_database_config

# Schema files location
SCHEMA_DIR="$PROJECT_DIR/db-init"

print_stage_header "Stage 0: Initialize Database"

# Verify schema directory exists
if [ ! -d "$SCHEMA_DIR" ]; then
    log_error "Schema directory not found: $SCHEMA_DIR"
    exit 1
fi

log_success "Schema files found"

cd "$PROJECT_DIR"

# Check if the container exists and remove it if RESET_DB is true
if docker ps -a --filter "name=${POSTGRES_CONTAINER_NAME}" --format "{{.Names}}" | grep -q "${POSTGRES_CONTAINER_NAME}"; then
    if [ "$RESET_DB" = true ]; then
        log_info "Removing existing '${POSTGRES_CONTAINER_NAME}' container..."
        if docker rm -f "${POSTGRES_CONTAINER_NAME}"; then
            log_success "Existing '${POSTGRES_CONTAINER_NAME}' container removed."
        else
            log_error "Failed to remove existing '${POSTGRES_CONTAINER_NAME}' container."
            exit 1
        fi
    fi
fi

# Start PostgreSQL container
log_info "Starting PostgreSQL container..."
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

log_success "Database initialized successfully"
log_info "Database is ready for data ingestion"

print_stage_footer "0" "01-setup-generator.sh"
