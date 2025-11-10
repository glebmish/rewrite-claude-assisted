#!/usr/bin/env bash
set -euo pipefail

# Script: 04-create-image.sh
# Purpose: Create Docker image with pre-loaded recipe data using pg_dump/restore approach
#
# Why not docker commit?
# The pgvector base image has VOLUME ["/var/lib/postgresql/data"] which creates
# an anonymous volume. Docker commit doesn't capture volume data, so we use
# pg_dump to export data and build an image that restores it on first boot.

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
DB_PASSWORD="${DB_PASSWORD:-changeme}"

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
    psql -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT COUNT(*) FROM recipes;" | tr -d ' ')

if [ "$RECIPE_COUNT" -eq 0 ]; then
    echo "✗ Error: Database is empty (0 recipes)"
    echo "  Run 03-ingest-docs.py first"
    exit 1
fi

echo "✓ Database contains $RECIPE_COUNT recipes"

# Get database size
DB_SIZE=$(docker exec "$POSTGRES_CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" \
    -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));" | tr -d ' ')

echo "✓ Database size: $DB_SIZE"

# Create dump directory
DUMP_DIR="$PROJECT_DIR/build"
mkdir -p "$DUMP_DIR"

# Export database using pg_dump
echo ""
echo "→ Exporting database to SQL dump..."
DUMP_FILE="$DUMP_DIR/recipes-dump.sql"

if docker exec "$POSTGRES_CONTAINER_NAME" \
    pg_dump -U "$DB_USER" -d "$DB_NAME" \
    --no-owner --no-privileges \
    > "$DUMP_FILE"; then
    echo "✓ Database exported to: $DUMP_FILE"
else
    echo "✗ Error: Failed to export database"
    exit 1
fi

# Get dump file size
DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
echo "✓ Dump file size: $DUMP_SIZE"

# Create entrypoint script that loads data on first boot
ENTRYPOINT_FILE="$DUMP_DIR/docker-entrypoint.sh"
cat > "$ENTRYPOINT_FILE" <<'EOF'
#!/usr/bin/env bash
set -e

# This script runs on container startup
# It loads the pre-dumped data if the database is empty

POSTGRES_USER="${POSTGRES_USER:-mcp_user}"
POSTGRES_DB="${POSTGRES_DB:-openrewrite_recipes}"
DATA_LOADED_FLAG="/var/lib/postgresql/data/.data-loaded"

# Start PostgreSQL in background
docker-entrypoint.sh postgres &
PG_PID=$!

# Wait for PostgreSQL to be ready
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 1
done

# Check if data has already been loaded
if [ ! -f "$DATA_LOADED_FLAG" ]; then
    echo "Loading recipe data from dump..."

    # Load the dump file
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < /docker-entrypoint-initdb.d/recipes-dump.sql

    # Mark as loaded
    touch "$DATA_LOADED_FLAG"

    RECIPE_COUNT=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM recipes;" | tr -d ' ')
    echo "✓ Loaded $RECIPE_COUNT recipes"
else
    echo "✓ Data already loaded, skipping..."
fi

# Bring PostgreSQL to foreground
wait $PG_PID
EOF

chmod +x "$ENTRYPOINT_FILE"
echo "✓ Created entrypoint script"

# Create Dockerfile
DOCKERFILE="$DUMP_DIR/Dockerfile"
cat > "$DOCKERFILE" <<EOF
FROM pgvector/pgvector:pg16

# Copy database dump
COPY recipes-dump.sql /docker-entrypoint-initdb.d/recipes-dump.sql

# Copy schema initialization scripts
COPY db-init/01-create-extensions.sql /docker-entrypoint-initdb.d/01-create-extensions.sql
COPY db-init/02-create-schema.sql /docker-entrypoint-initdb.d/02-create-schema.sql

# Set default environment variables
ENV POSTGRES_DB=openrewrite_recipes \\
    POSTGRES_USER=mcp_user \\
    POSTGRES_PASSWORD=changeme

# Metadata
LABEL org.openrewrite.recipes.count="$RECIPE_COUNT" \\
      org.openrewrite.recipes.date="$DATE_TAG" \\
      org.openrewrite.recipes.size="$DB_SIZE"
EOF

echo "✓ Created Dockerfile"

# Copy schema files
cp -r "$PROJECT_DIR/db-init" "$DUMP_DIR/"
echo "✓ Copied schema files"

# Build Docker image
echo ""
echo "→ Building Docker image..."
echo "  Image: ${IMAGE_NAME}:${DATE_TAG}"

if docker build \
    -t "${IMAGE_NAME}:${DATE_TAG}" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    "$DUMP_DIR"; then
    echo "✓ Image built successfully"
else
    echo "✗ Error: Failed to build image"
    exit 1
fi

# Get image size
IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "{{.Size}}")
echo "✓ Image size: $IMAGE_SIZE"

# Push to registry if configured
if [ -n "$REGISTRY_URL" ]; then
    echo ""
    echo "→ Pushing to registry..."

    # Tag for registry
    if docker push "${IMAGE_NAME}:${DATE_TAG}" && \
       docker push "${IMAGE_NAME}:${IMAGE_TAG}"; then
        echo "✓ Pushed to registry: ${IMAGE_NAME}"
    else
        echo "✗ Warning: Failed to push to registry"
        echo "  You can push manually later:"
        echo "  docker push ${IMAGE_NAME}:${DATE_TAG}"
        echo "  docker push ${IMAGE_NAME}:${IMAGE_TAG}"
    fi
else
    echo ""
    echo "ℹ  Registry URL not configured - image is local only"
    echo "  To push to a registry, set REGISTRY_URL in .env"
fi

# Clean up build artifacts
echo ""
echo "→ Cleaning up build artifacts..."
rm -f "$DUMP_FILE" "$ENTRYPOINT_FILE" "$DOCKERFILE"
rm -rf "$DUMP_DIR/db-init"
echo "✓ Cleanup complete"

echo ""
echo "========================================="
echo "✓ Stage 4 Complete"
echo "========================================="
echo "Created images:"
echo "  - ${IMAGE_NAME}:${DATE_TAG}"
echo "  - ${IMAGE_NAME}:${IMAGE_TAG}"
if [ -n "$REGISTRY_URL" ]; then
    echo "  Pushed to registry: ${IMAGE_NAME}"
fi
echo ""
echo "Image contains:"
echo "  - $RECIPE_COUNT recipes"
echo "  - $DB_SIZE database"
echo "  - $IMAGE_SIZE total size"
echo ""
echo "To use this image:"
echo "  docker run -d -p 5432:5432 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Or update mcp-server/docker-compose.yml:"
echo "  services:"
echo "    postgres:"
echo "      image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "========================================="
echo "✓ Pipeline Complete!"
echo "========================================="
