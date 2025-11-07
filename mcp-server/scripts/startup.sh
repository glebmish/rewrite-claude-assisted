#!/bin/bash
# Startup script for OpenRewrite MCP Server
# Phase 1: Starts MCP server only
# Phase 2+: Will also start PostgreSQL Docker container

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project directory
cd "$PROJECT_DIR"

# Load environment variables if .env file exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Activate virtual environment
if [ ! -d "venv" ]; then
    echo "Error: Virtual environment not found at $PROJECT_DIR/venv" >&2
    echo "Please run: python3 -m venv venv && venv/bin/pip install -r requirements.txt" >&2
    exit 1
fi

# Phase 2+: Check if PostgreSQL container should be started
# if [ "$START_DATABASE" = "true" ]; then
#     echo "Starting PostgreSQL container..." >&2
#     docker-compose up -d postgres
#
#     # Wait for database to be ready
#     echo "Waiting for database to be ready..." >&2
#     until docker-compose exec -T postgres pg_isready -U "$DB_USER" -d "$DB_NAME"; do
#         sleep 1
#     done
#     echo "Database is ready!" >&2
# fi

# Start MCP server
exec "$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/src/server.py"
