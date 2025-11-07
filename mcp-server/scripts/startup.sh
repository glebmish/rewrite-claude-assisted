#!/bin/bash
# Startup script for OpenRewrite MCP Server (Phase 2)
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
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-openrewrite_recipes}"
DB_USER="${DB_USER:-mcp_user}"
DB_PASSWORD="${DB_PASSWORD:-changeme}"

# Export for docker-compose
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
    echo "Please run: python3 -m venv venv && venv/bin/pip install -r requirements.txt" >&2
    exit 1
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found. Please install Docker to use Phase 2 MCP server." >&2
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose not found. Please install docker-compose." >&2
    exit 1
fi

# Start PostgreSQL container
echo "Starting PostgreSQL container..." >&2
docker-compose up -d postgres

# Wait for database to be ready
echo "Waiting for database to be ready..." >&2
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker-compose exec -T postgres pg_isready -U "$DB_USER" -d "$DB_NAME" 2>/dev/null; then
        echo "✅ Database is ready!" >&2
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "Error: Database failed to start after ${MAX_RETRIES} seconds" >&2
        docker-compose logs postgres >&2
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
"; then
    echo "Error: Cannot connect to database" >&2
    exit 1
fi

# Check if database needs to be seeded
NEEDS_SEED=$("$PROJECT_DIR/venv/bin/python" -c "
import asyncio
import asyncpg
import sys

async def check():
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
        if count == 0:
            print('yes')
        else:
            print('no')
    except Exception:
        print('yes')

asyncio.run(check())
" 2>/dev/null || echo "yes")

if [ "$NEEDS_SEED" = "yes" ]; then
    echo "Database is empty, seeding with initial data..." >&2
    "$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/scripts/seed_db.py" >&2
fi

# Start MCP server
echo "Starting MCP server..." >&2
exec "$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/src/server.py"
