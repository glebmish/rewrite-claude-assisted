# OpenRewrite MCP Server

A Model Context Protocol (MCP) server that provides Claude Code with access to OpenRewrite recipe discovery and documentation.

## Current Status: Phase 1 (Mock Implementation)

This is Phase 1 of the implementation, featuring:
- ✅ Working MCP server with stdio transport
- ✅ Three functional tools (test_connection, find_recipes, get_recipe)
- ✅ Mock data for testing and validation
- ✅ Claude Code integration ready

**Future Phases:**
- Phase 2: PostgreSQL with pgvector integration
- Phase 3: Real RAG-based recipe search with embeddings
- Phase 4: Data indexing and Docker distribution

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
- pip
- Claude Code

### Setup Steps

1. **Clone or navigate to the mcp-server directory:**
   ```bash
   cd /home/glebmish/projects/rewrite-claude-assisted/mcp-server
   ```

2. **Create and activate virtual environment (if not already done):**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Linux/Mac
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Create .env file (optional for Phase 1):**
   ```bash
   cp .env.example .env
   ```

## Configuration for Claude Code

### Option 1: Using .mcp.json (Project-level)

Copy or symlink the `.mcp.json` file to your project root or Claude Code will automatically detect it in the mcp-server directory:

```json
{
  "mcpServers": {
    "openrewrite-assistant": {
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
claude mcp add --transport stdio openrewrite-assistant -- /home/glebmish/projects/rewrite-claude-assisted/mcp-server/scripts/startup.sh
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
2. You should see "openrewrite-assistant" listed
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

## Mock Data (Phase 1)

The current implementation includes mock data for the following recipes:
- Spring Boot 3.0 Migration
- JUnit 4 to JUnit 5 Migration
- Java 17 Migration
- Secure Random Number Generation
- Remove Unused Imports
- javax to jakarta Migration
- Log4j to SLF4J Migration

## Project Structure

```
mcp-server/
├── src/
│   ├── server.py              # Main MCP server
│   ├── config.py              # Configuration management
│   ├── tools/
│   │   ├── test_connection.py # Health check tool
│   │   ├── find_recipes.py    # Recipe search (mock)
│   │   └── get_recipe.py      # Recipe documentation (mock)
├── scripts/
│   └── startup.sh             # Server startup script
├── requirements.txt           # Python dependencies
├── .env.example              # Environment template
├── .mcp.json                 # Claude Code configuration
└── README.md                 # This file
```

## Troubleshooting

### Server not connecting
- Check that the virtual environment is activated
- Verify Python dependencies are installed: `pip list | grep mcp`
- Check Claude Code logs: `~/Library/Logs/Claude/mcp-server-openrewrite-assistant.log`
- Ensure the startup script is executable: `chmod +x scripts/startup.sh`

### Tools not appearing
- Restart Claude Code after configuration changes
- Run `/mcp` command to verify server is loaded
- Check stderr logs for any server errors

### Import errors in server.py
- Make sure you're running from the correct directory
- The server must be started via `startup.sh` which sets proper paths
- Verify all dependencies are installed in the virtual environment

## Logging

- All logs are written to **stderr only** (never stdout, which would corrupt JSON-RPC)
- Logs include timestamps, log levels, and detailed error information
- Check Claude Code's MCP logs for server output

## Next Steps (Future Phases)

**Phase 2**: Database Integration
- PostgreSQL with pgvector Docker setup
- Database schema creation
- Connection pooling

**Phase 3**: Real Implementation
- sentence-transformers embeddings
- Vector similarity search
- Real recipe documentation retrieval

**Phase 4**: Data Distribution
- Recipe data ingestion pipeline
- Docker image with pre-loaded data
- Version management

## Contributing

This is part of the rewrite-claude-assisted project. See the main project documentation for contribution guidelines.

## License

[Add license information]

## Support

For issues or questions, please refer to the main project documentation or create an issue in the project repository.
