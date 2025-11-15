#!/bin/bash
# Startup script for OpenRewrite MCP Server
# Automatically manages PostgreSQL Docker container lifecycle

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project directory
cd "$PROJECT_DIR"

# Load environment variables if .env file exists
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Set defaults for database configuration
DB_IMAGE_NAME="${DB_IMAGE_NAME}"
DB_IMAGE_TAG="${DB_IMAGE_TAG}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"

# Export for docker-compose
export DB_IMAGE_NAME DB_IMAGE_TAG
export DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD

# Cleanup function to stop Docker container
cleanup() {
    echo "Shutting down MCP server..." >&2
    if command -v docker-compose &> /dev/null; then
        echo "Stopping PostgreSQL container..." >&2
        docker-compose down >&2 2>&1 || true
    fi
    exit 0
}

# Register cleanup on script exit
trap cleanup EXIT INT TERM

# Activate virtual environment
if [ ! -d "venv" ]; then
    echo "Error: Virtual environment not found at $PROJECT_DIR/venv" >&2
    echo "Please run: ./scripts/setup.sh" >&2
    exit 1
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found. Please install Docker." >&2
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose not found. Please install docker-compose." >&2
    exit 1
fi

# Check if required image exists
FULL_IMAGE="${DB_IMAGE_NAME}:${DB_IMAGE_TAG}"
if ! docker image inspect "$FULL_IMAGE" &> /dev/null; then
    echo "Error: Database image not found: $FULL_IMAGE" >&2
    echo "Please run the setup script first: ./scripts/setup.sh" >&2
    exit 1
fi

echo "Using database image: $FULL_IMAGE" >&2

# Start PostgreSQL container
echo "Starting PostgreSQL container..." >&2
docker-compose up -d postgres < /dev/null

# Wait for database to be ready
echo "Waiting for database to be ready..." >&2
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker-compose exec -T postgres pg_isready -U "$DB_USER" -d "$DB_NAME" < /dev/null 2>/dev/null; then
        echo "✅ PostgreSQL is accepting connections" >&2
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "Error: Database failed to start after ${MAX_RETRIES} seconds" >&2
        docker-compose logs postgres < /dev/null >&2
        exit 1
    fi
    sleep 1
done

# Wait for initialization scripts to complete
# The database might be accepting connections but init scripts may still be running
echo "Waiting for database initialization to complete..." >&2
MAX_INIT_RETRIES=60
INIT_RETRY_COUNT=0

while [ $INIT_RETRY_COUNT -lt $MAX_INIT_RETRIES ]; do
    # Check if the recipes table exists (means init scripts completed)
    if docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc \
        "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'recipes');" < /dev/null 2>/dev/null | grep -q "t"; then
        echo "✅ Database initialization complete!" >&2
        break
    fi
    INIT_RETRY_COUNT=$((INIT_RETRY_COUNT + 1))
    if [ $INIT_RETRY_COUNT -eq $MAX_INIT_RETRIES ]; then
        echo "Error: Database initialization failed after ${MAX_INIT_RETRIES} seconds" >&2
        echo "Container logs:" >&2
        docker-compose logs postgres < /dev/null >&2
        exit 1
    fi
    sleep 1
done

# After init scripts complete, database restarts. Wait a bit for it to be ready for external connections
echo "Waiting for database to be ready for external connections..." >&2
sleep 3

# Verify database is accepting connections on the exposed port
EXTERNAL_RETRY_COUNT=0
MAX_EXTERNAL_RETRIES=10
while [ $EXTERNAL_RETRY_COUNT -lt $MAX_EXTERNAL_RETRIES ]; do
    if docker-compose exec -T postgres pg_isready -U "$DB_USER" -d "$DB_NAME" -h localhost < /dev/null 2>/dev/null; then
        echo "✅ Database ready for external connections" >&2
        break
    fi
    EXTERNAL_RETRY_COUNT=$((EXTERNAL_RETRY_COUNT + 1))
    if [ $EXTERNAL_RETRY_COUNT -eq $MAX_EXTERNAL_RETRIES ]; then
        echo "Error: Database not ready for external connections after ${MAX_EXTERNAL_RETRIES} attempts" >&2
        docker-compose logs postgres < /dev/null >&2
        exit 1
    fi
    sleep 1
done

# Start MCP server
echo "Starting MCP server..." >&2
exec "$PROJECT_DIR/venv/bin/python" -u "$PROJECT_DIR/src/server.py"
