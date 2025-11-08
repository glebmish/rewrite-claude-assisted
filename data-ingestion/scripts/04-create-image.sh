#!/usr/bin/env bash
set -euo pipefail

# Script: 04-create-image.sh
# Purpose: Commit PostgreSQL container to a Docker image with recipe data

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
IMAGE_NAME="${IMAGE_NAME:-openrewrite-recipes-db}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY_URL="${REGISTRY_URL:-}"

# Generate date-based tag
DATE_TAG=$(date +%Y-%m-%d)

echo "========================================="
echo "Stage 4: Create Docker Image"
echo "========================================="

# Verify container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
    echo "✗ Error: Container '$POSTGRES_CONTAINER_NAME' is not running"
    echo "  Make sure the database is running and has been populated"
    echo "  Run: docker-compose ps"
    exit 1
fi

echo "✓ Container '$POSTGRES_CONTAINER_NAME' is running"

# Get recipe count from database
echo "→ Verifying database content..."
RECIPE_COUNT=$(docker exec "$POSTGRES_CONTAINER_NAME" \
    psql -U "${DB_USER:-mcp_user}" -d "${DB_NAME:-openrewrite_recipes}" \
    -t -c "SELECT COUNT(*) FROM recipes;" | tr -d ' ')

if [ "$RECIPE_COUNT" -eq 0 ]; then
    echo "✗ Error: Database is empty (0 recipes)"
    echo "  Run 03-ingest-docs.py first"
    exit 1
fi

echo "✓ Database contains $RECIPE_COUNT recipes"

# Get database size
DB_SIZE=$(docker exec "$POSTGRES_CONTAINER_NAME" \
    psql -U "${DB_USER:-mcp_user}" -d "${DB_NAME:-openrewrite_recipes}" \
    -t -c "SELECT pg_size_pretty(pg_database_size('${DB_NAME:-openrewrite_recipes}'));" | tr -d ' ')

echo "✓ Database size: $DB_SIZE"

# Commit container to image
echo ""
echo "→ Committing container to image..."
echo "  Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  Image: ${IMAGE_NAME}:${DATE_TAG}"

if docker commit \
    -m "OpenRewrite recipes database - $RECIPE_COUNT recipes - $DATE_TAG" \
    -a "rewrite-claude-assisted pipeline" \
    "$POSTGRES_CONTAINER_NAME" \
    "${IMAGE_NAME}:${DATE_TAG}"; then
    echo "✓ Image created: ${IMAGE_NAME}:${DATE_TAG}"
else
    echo "✗ Error: Failed to create image"
    exit 1
fi

# Tag as latest
docker tag "${IMAGE_NAME}:${DATE_TAG}" "${IMAGE_NAME}:${IMAGE_TAG}"
echo "✓ Tagged as: ${IMAGE_NAME}:${IMAGE_TAG}"

# Get image size
IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "{{.Size}}")
echo "✓ Image size: $IMAGE_SIZE"

# Push to registry if configured
if [ -n "$REGISTRY_URL" ]; then
    echo ""
    echo "→ Pushing to registry: $REGISTRY_URL"

    # Tag for registry
    REGISTRY_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}"
    docker tag "${IMAGE_NAME}:${DATE_TAG}" "${REGISTRY_IMAGE}:${DATE_TAG}"
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY_IMAGE}:${IMAGE_TAG}"

    # Push both tags
    if docker push "${REGISTRY_IMAGE}:${DATE_TAG}" && \
       docker push "${REGISTRY_IMAGE}:${IMAGE_TAG}"; then
        echo "✓ Pushed to registry: ${REGISTRY_IMAGE}"
    else
        echo "✗ Warning: Failed to push to registry"
        echo "  You can push manually later:"
        echo "  docker push ${REGISTRY_IMAGE}:${DATE_TAG}"
        echo "  docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}"
    fi
else
    echo ""
    echo "ℹ  Registry URL not configured - image is local only"
    echo "  To push to a registry, set REGISTRY_URL in .env"
fi

echo ""
echo "========================================="
echo "✓ Stage 4 Complete"
echo "========================================="
echo "Created images:"
echo "  - ${IMAGE_NAME}:${DATE_TAG}"
echo "  - ${IMAGE_NAME}:${IMAGE_TAG}"
if [ -n "$REGISTRY_URL" ]; then
    echo "  - ${REGISTRY_URL}/${IMAGE_NAME}:${DATE_TAG}"
    echo "  - ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
fi
echo ""
echo "Image contains:"
echo "  - $RECIPE_COUNT recipes"
echo "  - $DB_SIZE database"
echo "  - $IMAGE_SIZE total size"
echo ""
echo "To use this image:"
echo "  docker run -p 5432:5432 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Or update mcp-server/docker-compose.yml:"
echo "  services:"
echo "    postgres:"
echo "      image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "========================================="
echo "✓ Pipeline Complete!"
echo "========================================="
