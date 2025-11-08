#!/bin/bash
# Startup script for OpenRewrite MCP Server
# Automatically manages PostgreSQL Docker container lifecycle

set -e

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
DB_IMAGE_NAME="${DB_IMAGE_NAME:-openrewrite-recipes-db}"
DB_IMAGE_TAG="${DB_IMAGE_TAG:-latest}"
DB_IMAGE_REGISTRY="${DB_IMAGE_REGISTRY:-}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-openrewrite_recipes}"
DB_USER="${DB_USER:-mcp_user}"
DB_PASSWORD="${DB_PASSWORD:-changeme}"

# Export for docker-compose
export DB_IMAGE_NAME DB_IMAGE_TAG DB_IMAGE_REGISTRY
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
FULL_IMAGE="${DB_IMAGE_REGISTRY:+${DB_IMAGE_REGISTRY}/}${DB_IMAGE_NAME}:${DB_IMAGE_TAG}"
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
        echo "✅ Database is ready!" >&2
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

# Test database connection from Python
echo "Testing database connection..." >&2
if ! "$PROJECT_DIR/venv/bin/python" -c "
import asyncio
import asyncpg
import sys

async def test():
    try:
        conn = await asyncpg.connect(
            host='$DB_HOST',
            port=$DB_PORT,
            database='$DB_NAME',
            user='$DB_USER',
            password='$DB_PASSWORD',
            timeout=5
        )
        await conn.close()
        print('✅ Database connection successful', file=sys.stderr)
    except Exception as e:
        print(f'❌ Database connection failed: {e}', file=sys.stderr)
        sys.exit(1)

asyncio.run(test())
" < /dev/null; then
    echo "Error: Cannot connect to database" >&2
    exit 1
fi

# Verify recipes are available
RECIPE_COUNT=$("$PROJECT_DIR/venv/bin/python" -c "
import asyncio
import asyncpg
import sys

async def count():
    try:
        conn = await asyncpg.connect(
            host='$DB_HOST',
            port=$DB_PORT,
            database='$DB_NAME',
            user='$DB_USER',
            password='$DB_PASSWORD',
            timeout=5
        )
        count = await conn.fetchval('SELECT COUNT(*) FROM recipes')
        await conn.close()
        print(count)
    except Exception as e:
        print(0)

asyncio.run(count())
" < /dev/null 2>/dev/null || echo "0")

echo "✅ Database contains $RECIPE_COUNT recipes" >&2

# Start MCP server
echo "Starting MCP server..." >&2
exec "$PROJECT_DIR/venv/bin/python" -u "$PROJECT_DIR/src/server.py"
