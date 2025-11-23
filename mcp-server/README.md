# OpenRewrite MCP Server

A Model Context Protocol (MCP) server that provides Claude Code with access to OpenRewrite recipe discovery and documentation.

## Current Status: Phase 2 (PostgreSQL Database)

This is Phase 2 of the implementation, featuring:
- ✅ Working MCP server with stdio transport
- ✅ Three functional tools (test_connection, find_recipes, get_recipe)
- ✅ PostgreSQL database with pgvector extension
- ✅ Automated Docker container lifecycle management
- ✅ Simplified database schema: recipe_name + full markdown documentation
- ✅ Pre-loaded Docker image with ~1000+ recipes (no initialization needed)
- ✅ Claude Code integration ready

## Tools Available

### 1. test_connection
Test the MCP server connection and verify it's working correctly.

**Parameters:**
- `message` (optional): Message to echo back

**Example:**
```
Test connection to OpenRewrite assistant
```

### 2. find_recipes
Find OpenRewrite recipes based on your intent using semantic search.

**Parameters:**
- `intent` (required): Description of what you want to accomplish
- `limit` (optional, default=5): Maximum number of results
- `min_score` (optional, default=0.5): Minimum relevance threshold (0.0-1.0)

**Examples:**
```
Find recipes for migrating to Spring Boot 3
Find recipes for upgrading Java version
Find recipes to fix security issues
```

### 3. get_recipe
Get detailed documentation for a specific OpenRewrite recipe.

**Parameters:**
- `recipe_id` (required): Unique recipe identifier

**Example:**
```
Get documentation for org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0
```

## Installation

### Prerequisites
- Python 3.8 or higher
- Docker and Docker Compose
- Claude Code

### Quick Setup (Recommended)

Run the automated setup script:

```bash
cd mcp-server
./scripts/setup.sh
```

This one-time setup will:
- ✅ Verify Docker and Python installation
- ✅ Pull or build the pre-loaded database image (~500MB, contains ~1000+ recipes)
- ✅ Create Python virtual environment
- ✅ Install dependencies

**First run takes 5-10 minutes** (pulls or builds Docker image), subsequent starts are instant.

### Manual Setup (Alternative)

1. **Navigate to directory:**
   ```bash
   cd mcp-server
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env to customize image name/tag if needed
   ```

3. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. **Prepare database image:**
   ```bash
   # Option 1: Pull from registry (if available)
   docker pull openrewrite-recipes-db:latest

   # Option 2: Build locally (15-20 minutes)
   cd ../data-ingestion
   ./scripts/run-full-pipeline.sh
   ```

## Configuration for Claude Code

### Option 1: Using .mcp.json (Project-level)

Copy or symlink the `.mcp.json` file to your project root or Claude Code will automatically detect it in the mcp-server directory:

```json
{
  "mcpServers": {
    "openrewrite-mcp": {
      "type": "stdio",
      "command": "/home/glebmish/projects/rewrite-claude-assisted/mcp-server/scripts/startup.sh",
      "args": [],
      "env": {}
    }
  }
}
```

### Option 2: Using claude mcp add command

```bash
claude mcp add --transport stdio openrewrite-mcp -- /home/glebmish/projects/rewrite-claude-assisted/mcp-server/scripts/startup.sh
```

## Testing the Server

### 1. Test Locally (Optional)

You can test the server directly using the MCP Inspector or by running it manually:

```bash
cd /home/glebmish/projects/rewrite-claude-assisted/mcp-server
./scripts/startup.sh
```

The server will log to stderr when it's ready.

### 2. Test with Claude Code

After configuration, restart Claude Code and verify the server is connected:

1. In Claude Code, run the `/mcp` command to see available servers
2. You should see "openrewrite-mcp" listed
3. Try using one of the tools:

**Test connection:**
```
Use the test_connection tool to verify the server is working
```

**Find recipes:**
```
Use find_recipes to search for Spring Boot migration recipes
```

**Get recipe details:**
```
Use get_recipe to get documentation for org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0
```
