#!/usr/bin/env bash
# Script: verify-setup.sh
# Purpose: Verify that OpenRewrite Recipe Assistant setup is working correctly
# Usage: ./scripts/verify-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHECKS_PASSED=0
CHECKS_FAILED=0

log_check() {
    echo -e "${BLUE}➤${NC}  Verifying $1..."
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
    CHECKS_FAILED=$((CHECKS_FAILED+1))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Setup Verification                                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. MCP server files exist
log_check "MCP server files"
if [ -f "$PROJECT_ROOT/mcp-server/src/server.py" ] && \
   [ -f "$PROJECT_ROOT/mcp-server/requirements.txt" ] && \
   [ -f "$PROJECT_ROOT/mcp-server/docker-compose.yml" ]; then
    log_success "MCP server files present"
else
    log_error "MCP server files missing"
fi

# 2. Python virtual environment
log_check "Python virtual environment"
if [ -d "$PROJECT_ROOT/mcp-server/venv" ]; then
    log_success "Virtual environment exists"

    # Check if dependencies are installed
    if "$PROJECT_ROOT/mcp-server/venv/bin/python" -c "import mcp, asyncpg, sentence_transformers" &> /dev/null; then
        log_success "Python dependencies installed"
    else
        log_error "Python dependencies missing or incomplete"
    fi
else
    log_error "Python virtual environment not found"
fi

# 3. Docker image
log_check "Docker image"
cd "$PROJECT_ROOT/mcp-server"
if [ -f ".env" ]; then
    source .env
    IMAGE="${DB_IMAGE_NAME}:${DB_IMAGE_TAG}"
elif [ -f ".env.example" ]; then
    source .env.example
    IMAGE="${DB_IMAGE_NAME}:${DB_IMAGE_TAG}"
else
    IMAGE="glebmish/openrewrite-recipes-db:latest"
fi

if docker image inspect "$IMAGE" &> /dev/null; then
    log_success "Docker image available: $IMAGE"
else
    log_error "Docker image not found: $IMAGE"
    echo "   Run: docker pull $IMAGE"
fi
cd "$PROJECT_ROOT"

# 4. Gradle build
log_check "Gradle build"
if [ -f "$PROJECT_ROOT/gradlew" ]; then
    if [ -f "$PROJECT_ROOT/build.gradle" ]; then
        log_success "Gradle project configured"
    else
        log_error "build.gradle missing"
    fi
else
    log_error "Gradle wrapper missing"
fi

# 5. Claude Code commands
log_check "Claude Code workflow commands"
if [ -f "$PROJECT_ROOT/.claude/commands/rewrite-assist.md" ]; then
    log_success "Main workflow command present"
else
    log_error "Main workflow command missing"
fi

# 6. MCP server runtime test
log_check "MCP server startup and connectivity"
cd "$PROJECT_ROOT/mcp-server"
if [ -x "scripts/startup.sh" ]; then
    log_success "MCP startup script ready"

    # Start server in background, capture output to temp file
    TEMP_LOG="/tmp/mcp-verify-$$.log"
    ./scripts/startup.sh > "$TEMP_LOG" 2>&1 &
    SERVER_PID=$!

    # Wait for "Server ready" message (up to 30 seconds)
    SUCCESS=false
    for i in {1..30}; do
        if grep -q "Server ready to accept connections" "$TEMP_LOG" 2>/dev/null; then
            SUCCESS=true
            break
        fi
        # Check if process died unexpectedly
        if ! kill -0 $SERVER_PID 2>/dev/null; then
            break
        fi
        sleep 1
    done

    # Clean up server process (SIGTERM triggers cleanup trap in startup.sh)
    if kill -0 $SERVER_PID 2>/dev/null; then
        kill -TERM $SERVER_PID 2>/dev/null
        # Wait for graceful shutdown (up to 5 seconds)
        for i in {1..10}; do
            if ! kill -0 $SERVER_PID 2>/dev/null; then
                break
            fi
            sleep 0.5
        done
        # Force kill if still running
        kill -9 $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi

    # Wait for docker-compose cleanup (startup.sh trap handles container shutdown)
    sleep 2

    # Report result
    if [ "$SUCCESS" = true ]; then
        log_success "MCP server started successfully and connected to database"
    else
        # Diagnose failure from logs
        if grep -q "Failed to connect to database" "$TEMP_LOG" 2>/dev/null; then
            log_error "MCP server failed: database connection error"
        elif grep -q "Virtual environment not found" "$TEMP_LOG" 2>/dev/null; then
            log_error "MCP server failed: virtual environment missing"
        elif grep -q "Docker.*not found" "$TEMP_LOG" 2>/dev/null; then
            log_error "MCP server failed: Docker not available"
        elif grep -q "Database image not found" "$TEMP_LOG" 2>/dev/null; then
            log_error "MCP server failed: database image not pulled"
        elif ! kill -0 $SERVER_PID 2>/dev/null && [ ! "$SUCCESS" = true ]; then
            log_error "MCP server process died during startup"
            echo "   Error details:" >&2
            grep -i "error\|failed\|exception" "$TEMP_LOG" | tail -5 >&2 || tail -10 "$TEMP_LOG" >&2
        else
            log_error "MCP server failed to start within 30 seconds"
            echo "   Last 10 lines of output:" >&2
            tail -10 "$TEMP_LOG" >&2
        fi
    fi

    # Cleanup temp log
    rm -f "$TEMP_LOG"
else
    log_error "MCP startup script missing or not executable"
fi
cd "$PROJECT_ROOT"

# 7. Eval framework
log_check "Evaluation framework"
if [ -f "$PROJECT_ROOT/eval/entrypoint.sh" ] && [ -d "$PROJECT_ROOT/eval/suites" ]; then
    log_success "Evaluation framework present"
else
    log_warning "Evaluation framework incomplete (optional)"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
if [ $CHECKS_FAILED -eq 0 ]; then
    echo "║  ✓ All Verifications Passed!                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Setup verified: $CHECKS_PASSED checks passed"
    echo ""
    echo "System is ready to use!"
    echo ""
    exit 0
else
    echo "║  ⚠ Verification Issues Found                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_warning "Passed: $CHECKS_PASSED, Failed: $CHECKS_FAILED"
    echo ""
    echo "Some components may not work correctly."
    echo "Review errors above and run ./scripts/quick-setup.sh again if needed."
    echo ""
    exit 1
fi
