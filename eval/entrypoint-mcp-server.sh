#!/bin/bash
set -euxo pipefail


# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

# Parse arguments
STRICT_MODE=false
DEBUG_MODE=false
PR_URL=""
TIMEOUT_MINUTES=60
SETTINGS_FILE="$(dirname "$0")/settings.json"

while [[ $# -gt 0 ]]; do
    case $1 in
        --strict)
            STRICT_MODE=true
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --timeout)
            TIMEOUT_MINUTES="$2"
            shift 2
            ;;
        --settings-file)
            SETTINGS_FILE="$2"
            shift 2
            ;;
        *)
            PR_URL="$1"
            shift
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PR_URL" ]]; then
    echo "Error: PR_URL is required"
    exit 1
fi

CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN}"
GH_TOKEN="${GH_TOKEN}"
SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY}"

# Export to make available for tools
export CLAUDE_CODE_OAUTH_TOKEN
export GH_TOKEN

pwd
tree -a .

log "Setting up SSH key"
mkdir -p /root/.ssh
echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-keyscan github.com >> /root/.ssh/known_hosts
log "SSH key configured successfully"

# Setup MCP server environment
log "Setting up MCP server environment"
MCP_DIR="$(cd "$(dirname "$0")/../mcp-server" && pwd)"
SCRIPTS_DIR="$MCP_DIR/scripts"
if [[ -d "$MCP_DIR" ]]; then
    # Create symlink to pre-installed venv if it doesn't exist
    if [[ ! -d "$MCP_DIR/venv" ]] && [[ -d "/opt/mcp-venv" ]]; then
        log "Creating symlink to pre-installed MCP venv"
        ln -s /opt/mcp-venv "$MCP_DIR/venv"
    fi

    # Make scripts executable
    chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true

    # Configure MCP database connection
    if [[ "${MCP_USE_EXTERNAL_DB:-false}" == "true" ]]; then
        log "Using external PostgreSQL service (GitHub Actions mode)"
        log "Database host: ${MCP_DB_HOST:-postgres}"

        # Copy .env.example and override for external database
        if [[ -f "$MCP_DIR/.env.example" ]]; then
            cp "$MCP_DIR/.env.example" "$MCP_DIR/.env"
            # Override connection settings for external database
            sed -i "s/^DB_HOST=.*/DB_HOST=${MCP_DB_HOST:-postgres}/" "$MCP_DIR/.env"
            sed -i "s/^DB_PORT=.*/DB_PORT=${MCP_DB_PORT:-5432}/" "$MCP_DIR/.env"
            sed -i "s/^DB_NAME=.*/DB_NAME=${MCP_DB_NAME:-openrewrite_recipes}/" "$MCP_DIR/.env"
            sed -i "s/^DB_USER=.*/DB_USER=${MCP_DB_USER:-mcp_user}/" "$MCP_DIR/.env"
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${MCP_DB_PASSWORD:-changeme}/" "$MCP_DIR/.env"
            # Add external DB flag
            echo "USE_EXTERNAL_DB=true" >> "$MCP_DIR/.env"
            log "MCP configured to use external PostgreSQL"
        else
            log "Warning: .env.example not found at $MCP_DIR/.env.example"
        fi
    else
        log "Using local Docker mode (will start PostgreSQL via docker-compose)"
        # Copy .env.example if .env doesn't exist
        if [[ ! -f "$MCP_DIR/.env" ]] && [[ -f "$MCP_DIR/.env.example" ]]; then
            log "Creating .env from .env.example"
            cp "$MCP_DIR/.env.example" "$MCP_DIR/.env"
        fi
        # Pre-pull PostgreSQL image to avoid delay on first MCP call
        if command -v docker &> /dev/null; then
            log "Pre-pulling PostgreSQL image for MCP server..."
            docker pull bboygleb/openrewrite-recipes-db:latest 2>&1 | grep -E "(Pulling|Downloaded|Status:|Digest:)" || true
            log "MCP PostgreSQL image ready"
        else
            log "Warning: Docker not available, assuming PostgreSQL will be started externally"
        fi
    fi
else
    log "Warning: MCP server directory not found at $MCP_DIR"
fi

# Source shared settings parser
source "$(dirname "$0")/parse-settings.sh"

# Parse settings file to get tool restrictions
log "Parsing settings file: $SETTINGS_FILE"
parse_settings_file "$SETTINGS_FILE"

# Execute rewrite-assist command
log "Executing rewrite-assist command"
START_TIME=$(date +%s)

# Build the claude command
CLAUDE_CMD="claude --model claude-sonnet-4-5"

# Add debug flag if enabled
if [[ "$DEBUG_MODE" == "true" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --debug"
fi

# Add tool restrictions if available
if [[ -n "$CLAUDE_ALLOWED_TOOLS" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --allowedTools \"$CLAUDE_ALLOWED_TOOLS\""
fi
if [[ -n "$CLAUDE_DISALLOWED_TOOLS" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --disallowedTools \"$CLAUDE_DISALLOWED_TOOLS\""
fi

# Add MCP arguments
CLAUDE_CMD="$CLAUDE_CMD --mcp-config '{\"mcpServers\":{\"openrewrite-mcp\":{\"type\":\"stdio\",\"command\":\"$SCRIPTS_DIR/startup.sh\",\"args\":[],\"env\":{}}}}' --strict-mcp-config"

CLAUDE_PROMPT="/rewrite-assist $PR_URL."
if [[ "$STRICT_MODE" == "true" ]]; then
    CLAUDE_PROMPT="$CLAUDE_PROMPT Give up IMMEDIATELY when something fails (tool access is not granted, tool use failed). Finish the conversation and explicitly state the reason you did. Print full tool name and command."
fi
CLAUDE_CMD="$CLAUDE_CMD -p \"$CLAUDE_PROMPT\""

echo "$CLAUDE_CMD"

timeout 120 $SCRIPTS_DIR/startup.sh

log "Evaluation complete"
exit $EXIT_CODE
