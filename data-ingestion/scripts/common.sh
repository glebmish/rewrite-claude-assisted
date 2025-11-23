#!/usr/bin/env bash
set -euo pipefail
#
# Common utilities for data ingestion scripts
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
#

# Initialize script environment (must be called first in each script)
# Sets up: error handling, absolute paths, environment variables, colors
init_script() {
    # Enable strict error handling
    set -euo pipefail

    # Get absolute paths
    # Note: BASH_SOURCE[1] refers to the script that called init_script()
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

    # Export for use in functions
    export SCRIPT_DIR
    export PROJECT_DIR

    # Load environment variables from .env
    if [ -f "$PROJECT_DIR/.env" ]; then
        set -a
        source "$PROJECT_DIR/.env"
        set +a
    fi

    # Setup color codes for logging
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    # Export colors for use in functions
    export RED GREEN YELLOW BLUE NC
}

# Logging functions with consistent colored output

log_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

# Stage formatting functions

print_stage_header() {
    local stage_title="$1"
    echo "========================================="
    echo "$stage_title"
    echo "========================================="
}

print_stage_footer() {
    local stage_num="$1"
    local next_script="${2:-}"
    echo ""
    echo "========================================="
    echo "✓ Stage $stage_num Complete"
    echo "========================================="
    if [ -n "$next_script" ]; then
        echo ""
        echo "Next step: Run $next_script"
    fi
    echo ""
}

# Java configuration and validation

setup_java() {
    JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
    export JAVA_HOME

    if [ ! -d "$JAVA_HOME" ]; then
        log_error "JAVA_HOME directory not found: $JAVA_HOME"
        log_error "Available Java installations:"
        update-alternatives --list java || true
        return 1
    fi

    return 0
}

verify_java_version() {
    local required_version="$1"

    if ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -q "version \"$required_version"; then
        log_error "Java $required_version is required"
        log_error "Current JAVA_HOME: $JAVA_HOME"
        "$JAVA_HOME/bin/java" -version
        echo ""
        log_error "Available Java installations:"
        update-alternatives --list java || true
        return 1
    fi

    log_success "Java $required_version verified: $JAVA_HOME"
    return 0
}

# Generator repository configuration

setup_generator_paths() {
    GENERATOR_WORKSPACE="${GENERATOR_WORKSPACE}"
    GENERATOR_DIR="${GENERATOR_DIR}"
    GENERATOR_DIR_FULL="$GENERATOR_WORKSPACE/${GENERATOR_DIR}"
    GENERATOR_OUTPUT_DIR="${GENERATOR_OUTPUT_DIR}"

    export GENERATOR_WORKSPACE
    export GENERATOR_DIR
    export GENERATOR_DIR_FULL
    export GENERATOR_OUTPUT_DIR
}

verify_generator() {
    if [ ! -d "$GENERATOR_DIR_FULL" ]; then
        log_error "Generator directory not found: $GENERATOR_DIR_FULL"
        log_error "Run 01-setup-generator.sh first"
        return 1
    fi
    return 0
}

# Database configuration

setup_database_config() {
    DB_HOST="${DB_HOST}"
    DB_PORT="${DB_PORT}"
    DB_NAME="${DB_NAME}"
    DB_USER="${DB_USER}"
    DB_PASSWORD="${DB_PASSWORD}"
    POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME}"

    export DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD POSTGRES_CONTAINER_NAME
}
