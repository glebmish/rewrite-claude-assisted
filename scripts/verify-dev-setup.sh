#!/usr/bin/env bash
# Script: verify-dev-setup.sh
# Purpose: Verify development environment for rewrite-claude-assisted repo
# Usage: ./scripts/verify-dev-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MCP_DIR="$PROJECT_ROOT/plugin/mcp-server"

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
echo "║  Development Environment Verification                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. MCP server files exist
log_check "MCP server files"
if [ -f "$MCP_DIR/src/server.py" ] && \
   [ -f "$MCP_DIR/requirements.txt" ] && \
   [ -f "$MCP_DIR/docker-compose.yml" ]; then
    log_success "MCP server files present"
else
    log_error "MCP server files missing"
    echo "   Expected: $MCP_DIR/src/server.py, requirements.txt, docker-compose.yml"
fi

# 2. Python virtual environment with uv
log_check "Python virtual environment"
if [ -d "$MCP_DIR/venv" ]; then
    log_success "Virtual environment exists"

    # Check if dependencies are installed
    if "$MCP_DIR/venv/bin/python" -c "import mcp, asyncpg, sentence_transformers" &> /dev/null; then
        log_success "Python dependencies installed"
    else
        log_error "Python dependencies missing or incomplete"
        echo "   Run: cd $MCP_DIR && uv pip install -r requirements.txt"
    fi
else
    log_error "Python virtual environment not found"
    echo "   Run: scripts/setup-dev.sh"
fi

# 3. Docker image
log_check "Docker image"
cd "$MCP_DIR"
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

# 4. MCP configuration
log_check "MCP configuration"
if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
    log_success "Local MCP configuration present (.mcp.json)"
else
    log_error "Local MCP configuration missing (.mcp.json)"
    echo "   Run: scripts/setup-dev.sh"
fi

# 5. Plugin structure
log_check "Plugin structure"
if [ -d "$PROJECT_ROOT/plugin" ] && \
   [ -f "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json" ]; then
    log_success "Plugin structure present"
else
    log_error "Plugin structure missing"
fi

# 6. Plugin commands
log_check "Plugin commands"
COMMANDS_OK=true
for cmd in "rewrite-assist.md" "fetch-repos.md" "extract-intent.md" "verify-openrewrite-assist-prerequisites.md"; do
    if [ ! -f "$PROJECT_ROOT/plugin/commands/$cmd" ]; then
        log_error "Plugin command missing: $cmd"
        COMMANDS_OK=false
    fi
done
if [ "$COMMANDS_OK" = true ]; then
    log_success "Plugin commands present"
fi

# 7. Plugin agents
log_check "Plugin agents"
AGENTS_OK=true
for agent in "openrewrite-expert.md" "openrewrite-recipe-validator.md"; do
    if [ ! -f "$PROJECT_ROOT/plugin/agents/$agent" ]; then
        log_error "Plugin agent missing: $agent"
        AGENTS_OK=false
    fi
done
if [ "$AGENTS_OK" = true ]; then
    log_success "Plugin agents present"
fi

# 8. MCP startup script
log_check "MCP startup script"
if [ -x "$MCP_DIR/scripts/startup.sh" ]; then
    log_success "MCP startup script ready"
else
    log_error "MCP startup script missing or not executable"
fi

# 9. Evaluation framework
log_check "Evaluation framework"
if [ -d "$PROJECT_ROOT/eval" ] && \
   [ -f "$PROJECT_ROOT/eval/entrypoint.sh" ] && \
   [ -d "$PROJECT_ROOT/eval/suites" ]; then
    log_success "Evaluation framework present"
else
    log_warning "Evaluation framework incomplete (optional for development)"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
if [ $CHECKS_FAILED -eq 0 ]; then
    echo "║  ✓ All Verifications Passed!                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Development environment verified: $CHECKS_PASSED checks passed"
    echo ""
    echo "Environment is ready for development!"
    echo ""
    exit 0
else
    echo "║  ⚠ Verification Issues Found                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_warning "Passed: $CHECKS_PASSED, Failed: $CHECKS_FAILED"
    echo ""
    echo "Some components may not work correctly."
    echo "Review errors above and run scripts/setup-dev.sh again if needed."
    echo ""
    exit 1
fi
