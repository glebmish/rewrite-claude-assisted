#!/usr/bin/env bash
set -euo pipefail

# Script: 04-create-image.sh
# Purpose: Create Docker image with pre-loaded recipe data using pg_dump
#
# The pgvector base image has VOLUME ["/var/lib/postgresql/data"] which creates
# an anonymous volume. We use pg_dump to export data and let PostgreSQL's
# /docker-entrypoint-initdb.d mechanism load it on first boot.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Configuration with defaults
POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-openrewrite-postgres}"
IMAGE_NAME="${IMAGE_NAME:-bboygleb/openrewrite-recipes-db}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY_URL="${REGISTRY_URL:-}"
DB_USER="${DB_USER:-mcp_user}"
DB_NAME="${DB_NAME:-openrewrite_recipes}"

# Generate date-based tag
DATE_TAG=$(date +%Y-%m-%d)

echo "========================================="
echo "Stage 4: Create Docker Image"
echo "========================================="

# Verify container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
    echo "✗ Error: Container '$POSTGRES_CONTAINER_NAME' is not running"
    echo "  Make sure the database is running and has been populated"
    exit 1
fi

echo "✓ Container '$POSTGRES_CONTAINER_NAME' is running"

# Get recipe count and database size
echo "→ Verifying database content..."
RECIPE_COUNT=$(docker exec "$POSTGRES_CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT COUNT(*) FROM recipes;" | tr -d ' ')

if [ "$RECIPE_COUNT" -eq 0 ]; then
    echo "✗ Error: Database is empty (0 recipes)"
    exit 1
fi

DB_SIZE=$(docker exec "$POSTGRES_CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));" | tr -d ' ')

echo "✓ Database contains $RECIPE_COUNT recipes ($DB_SIZE)"

# Create build directory
BUILD_DIR="$PROJECT_DIR/build"
mkdir -p "$BUILD_DIR"

# Export database using pg_dump
echo ""
echo "→ Exporting database to SQL dump..."
if docker exec "$POSTGRES_CONTAINER_NAME" \
    pg_dump -U "$DB_USER" -d "$DB_NAME" \
    --no-owner --no-privileges \
    > "$BUILD_DIR/recipes-dump.sql"; then
    DUMP_SIZE=$(du -h "$BUILD_DIR/recipes-dump.sql" | cut -f1)
    echo "✓ Database exported ($DUMP_SIZE)"
else
    echo "✗ Error: Failed to export database"
    exit 1
fi

# Copy build context files
echo "→ Preparing build context..."
cp -r "$PROJECT_DIR/db-init" "$BUILD_DIR/"
cp "$PROJECT_DIR/Dockerfile" "$BUILD_DIR/"
echo "✓ Build context ready"

# Build Docker image
echo ""
echo "→ Building Docker image..."
if docker build \
    --build-arg RECIPE_COUNT="$RECIPE_COUNT" \
    --build-arg BUILD_DATE="$DATE_TAG" \
    --build-arg DB_SIZE="$DB_SIZE" \
    -t "${IMAGE_NAME}:${DATE_TAG}" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    "$BUILD_DIR"; then
    IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "{{.Size}}")
    echo "✓ Image built successfully ($IMAGE_SIZE)"
else
    echo "✗ Error: Failed to build image"
    exit 1
fi

# Push to registry if configured
if [ -n "$REGISTRY_URL" ]; then
    echo ""
    echo "→ Pushing to registry..."
    if docker push "${IMAGE_NAME}:${DATE_TAG}" && \
       docker push "${IMAGE_NAME}:${IMAGE_TAG}"; then
        echo "✓ Pushed to registry: ${IMAGE_NAME}"
    else
        echo "✗ Warning: Failed to push to registry"
    fi
fi

# Clean up build artifacts
echo ""
echo "→ Cleaning up build artifacts..."
rm -rf "$BUILD_DIR"
echo "✓ Cleanup complete"

echo ""
echo "========================================="
echo "✓ Stage 4 Complete"
echo "========================================="
echo "Created images:"
echo "  - ${IMAGE_NAME}:${DATE_TAG}"
echo "  - ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Image contains:"
echo "  - $RECIPE_COUNT recipes"
echo "  - $DB_SIZE database"
echo ""
echo "To use this image:"
echo "  docker run -d -p 5432:5432 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
