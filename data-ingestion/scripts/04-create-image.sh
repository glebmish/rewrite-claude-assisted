#!/usr/bin/env bash
set -euo pipefail

# Script: 04-create-image.sh
# Purpose: Create Docker image with pre-loaded recipe data using pg_dump
#
# The pgvector base image has VOLUME ["/var/lib/postgresql/data"] which creates
# an anonymous volume. We use pg_dump to export data and let PostgreSQL's
# /docker-entrypoint-initdb.d mechanism load it on first boot.

# Load common utilities
COMMON_LIB="$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COMMON_LIB"

# Initialize script environment
init_script

# Setup database configuration
setup_database_config

# Configuration with defaults
REGISTRY_PUSH=${REGISTRY_PUSH:-false}
IMAGE_NAME="${IMAGE_NAME}"
IMAGE_TAG="${IMAGE_TAG}"
REGISTRY_URL="${REGISTRY_URL:-}"

# Generate date-based tag
DATE_TAG=$(date +%Y-%m-%d)

print_stage_header "Stage 4: Create Docker Image"

# Verify container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
    log_error "Container '$POSTGRES_CONTAINER_NAME' is not running"
    log_error "Make sure the database is running and has been populated"
    exit 1
fi

log_success "Container '$POSTGRES_CONTAINER_NAME' is running"

# Get recipe count and database size
log_info "Verifying database content..."
RECIPE_COUNT=$(docker exec "$POSTGRES_CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT COUNT(*) FROM recipes;" | tr -d ' ')

if [ "$RECIPE_COUNT" -eq 0 ]; then
    log_error "Database is empty (0 recipes)"
    exit 1
fi

DB_SIZE=$(docker exec "$POSTGRES_CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));" | tr -d ' ')

log_success "Database contains $RECIPE_COUNT recipes ($DB_SIZE)"

# Create build directory
BUILD_DIR="$PROJECT_DIR/build"
mkdir -p "$BUILD_DIR"

# Export database using pg_dump
echo ""
log_info "Exporting database to SQL dump..."
if docker exec "$POSTGRES_CONTAINER_NAME" \
    pg_dump -U "$DB_USER" -d "$DB_NAME" \
    --no-owner --no-privileges \
    > "$BUILD_DIR/recipes-dump.sql"; then
    DUMP_SIZE=$(du -h "$BUILD_DIR/recipes-dump.sql" | cut -f1)
    log_success "Database exported ($DUMP_SIZE)"
else
    log_error "Failed to export database"
    exit 1
fi

# Copy build context files
log_info "Preparing build context..."
cp "$PROJECT_DIR/Dockerfile" "$BUILD_DIR/"
log_success "Build context ready"

# Build Docker image
echo ""
log_info "Building Docker image..."
if docker build \
    -t "${IMAGE_NAME}:${DATE_TAG}" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    "$BUILD_DIR"; then
    IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "{{.Size}}")
    log_success "Image built successfully ($IMAGE_SIZE)"
else
    log_error "Failed to build image"
    exit 1
fi

# Push to registry if configured
if [[ "$REGISTRY_PUSH" == "true" ]]; then
    echo ""
    log_info "Pushing to registry..."
    if docker push "${IMAGE_NAME}:${DATE_TAG}" && \
       docker push "${IMAGE_NAME}:${IMAGE_TAG}"; then
        log_success "Pushed to registry: ${IMAGE_NAME}"
    else
        log_warning "Failed to push to registry"
    fi
fi

# Clean up build artifacts
echo ""
log_info "Cleaning up build artifacts..."
rm -rf "$BUILD_DIR"
log_success "Cleanup complete"

echo ""
log_info "Created images:"
log_info "  - ${IMAGE_NAME}:${DATE_TAG}"
log_info "  - ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
log_info "Image contains:"
log_info "  - $RECIPE_COUNT recipes"
log_info "  - $DB_SIZE database"
echo ""
log_info "To use this image:"
log_info "  docker run -d -p 5432:5432 ${IMAGE_NAME}:${IMAGE_TAG}"

print_stage_footer "4" ""
