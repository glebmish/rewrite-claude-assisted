#!/usr/bin/env bash
# Script: check-prerequisites.sh
# Purpose: Validate runtime prerequisites for OpenRewrite Assist plugin
# Usage: ./scripts/check-prerequisites.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FAILED_CHECKS=0
WARNING_CHECKS=0

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
    ((WARNING_CHECKS++))
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  OpenRewrite Assist - Prerequisites Check                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Docker
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

# 2. Docker Compose
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

# 3. Python 3.8+ with venv
log_check "Python 3.8+ with venv"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

    if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
        log_success "Python $PYTHON_VERSION"

        # Check venv module
        if python3 -c "import venv" &> /dev/null; then
            log_success "Python venv module available"
        else
            log_error "Python venv module not found"
            echo "   Install: apt install python3-venv (Debian/Ubuntu)"
        fi
    else
        log_error "Python 3.8+ required, found Python $PYTHON_VERSION"
        echo "   Install: https://www.python.org/downloads/"
    fi
else
    log_error "Python 3 not found in PATH"
    echo "   Install: https://www.python.org/downloads/"
fi

# 4. Git
log_check "Git"
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    log_success "$GIT_VERSION"
else
    log_error "Git not found in PATH"
    echo "   Install: https://git-scm.com/downloads"
fi

# 5. GitHub CLI
log_check "GitHub CLI"
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n 1)
    log_success "$GH_VERSION"
else
    log_warning "GitHub CLI not found (optional but recommended)"
    echo "   Install for PR operations: https://cli.github.com/"
fi

# 6. jq (JSON processor)
log_check "jq"
if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version)
    log_success "$JQ_VERSION"
else
    log_error "jq not found"
    echo "   Install: https://jqlang.github.io/jq/download/"
fi

# 7. yq (YAML processor)
log_check "yq"
if command -v yq &> /dev/null; then
    YQ_VERSION=$(yq --version 2>&1 | head -n 1)
    log_success "$YQ_VERSION"
else
    log_error "yq not found"
    echo "   Install: https://github.com/mikefarah/yq#install"
fi

# 8. Disk space
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
    if [ $WARNING_CHECKS -eq 0 ]; then
        echo "║  ✓ All Prerequisites Met!                                 ║"
    else
        echo "║  ✓ Required Prerequisites Met (with warnings)             ║"
    fi
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "System ready for setup"
    if [ $WARNING_CHECKS -gt 0 ]; then
        log_warning "$WARNING_CHECKS optional prerequisite(s) missing"
    fi
    echo ""
    exit 0
else
    echo "║  ✗ Prerequisites Check Failed                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_error "$FAILED_CHECKS required prerequisite(s) missing"
    if [ $WARNING_CHECKS -gt 0 ]; then
        log_warning "$WARNING_CHECKS optional prerequisite(s) missing"
    fi
    echo ""
    echo "Please install missing prerequisites and run this script again."
    echo ""
    exit 1
fi
