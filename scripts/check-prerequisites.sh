#!/usr/bin/env bash
# Script: check-prerequisites.sh
# Purpose: Validate all prerequisites for OpenRewrite Recipe Assistant
# Usage: ./scripts/check-prerequisites.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FAILED_CHECKS=0

log_check() {
    echo -e "${BLUE}➤${NC}  Checking $1..."
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
    ((FAILED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Prerequisites Check                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Java 21
log_check "Java 21"
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VERSION" = "21" ]; then
        JAVA_FULL=$(java -version 2>&1 | head -n 1)
        log_success "Java 21 found: $JAVA_FULL"
    else
        log_error "Java 21 required, found Java $JAVA_VERSION"
        echo "   Install: https://adoptium.net/ or use SDKMAN: https://sdkman.io/"
    fi
else
    log_error "Java not found in PATH"
    echo "   Install: https://adoptium.net/"
fi

# 2. Docker
log_check "Docker"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log_success "$DOCKER_VERSION"

    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        log_success "Docker daemon is running"
    else
        log_error "Docker daemon is not running"
        echo "   Start Docker and try again"
    fi
else
    log_error "Docker not found in PATH"
    echo "   Install: https://docs.docker.com/get-docker/"
fi

# 3. Docker Compose
log_check "Docker Compose"
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    log_success "$COMPOSE_VERSION"
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    log_success "$COMPOSE_VERSION (plugin)"
else
    log_error "Docker Compose not found"
    echo "   Install: https://docs.docker.com/compose/install/"
fi

# 4. Python 3.8+
log_check "Python 3.8+"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

    if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
        log_success "Python $PYTHON_VERSION"
    else
        log_error "Python 3.8+ required, found Python $PYTHON_VERSION"
        echo "   Install: https://www.python.org/downloads/"
    fi
else
    log_error "Python 3 not found in PATH"
    echo "   Install: https://www.python.org/downloads/"
fi

# 5. Claude Code CLI
log_check "Claude Code CLI"
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown version")
    log_success "Claude Code CLI installed: $CLAUDE_VERSION"
else
    log_error "Claude Code CLI not found"
    echo "   Install: https://github.com/anthropics/claude-code"
fi

# 6. Git
log_check "Git"
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    log_success "$GIT_VERSION"
else
    log_error "Git not found in PATH"
    echo "   Install: https://git-scm.com/downloads"
fi

# 7. GitHub CLI
log_check "GitHub CLI"
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n 1)
    log_success "$GH_VERSION"
else
    log_error "GitHub CLI not found"
    echo "   Install for PR operations: https://cli.github.com/"
fi

# 8. jq (JSON processor)
log_check "jq"
if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version)
    log_success "$JQ_VERSION"
else
    log_error "jq not found"
    echo "   Install: https://jqlang.github.io/jq/download/"
fi

# 9. yq (YAML processor)
log_check "yq"
if command -v yq &> /dev/null; then
    YQ_VERSION=$(yq --version 2>&1 | head -n 1)
    log_success "$YQ_VERSION"
else
    log_error "yq not found"
    echo "   Install: https://github.com/mikefarah/yq#install"
fi

# 10. Disk space
log_check "Disk space"
AVAILABLE_GB=$(df -BG . | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$AVAILABLE_GB" -ge 2 ]; then
    log_success "Sufficient disk space: ${AVAILABLE_GB}GB available"
else
    log_warning "Low disk space: ${AVAILABLE_GB}GB available (2GB+ recommended)"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
if [ $FAILED_CHECKS -eq 0 ]; then
    echo "║  ✓ All Required Prerequisites Met!                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "System ready for setup"
    echo ""
    exit 0
else
    echo "║  ✗ Prerequisites Check Failed                             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_error "$FAILED_CHECKS prerequisite(s) missing"
    echo ""
    echo "Please install missing prerequisites and run this script again."
    echo ""
    exit 1
fi
