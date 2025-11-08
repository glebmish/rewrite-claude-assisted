# OpenRewrite MCP Server

A Model Context Protocol (MCP) server that provides Claude Code with access to OpenRewrite recipe discovery and documentation.

## Current Status: Phase 2 (PostgreSQL Database)

This is Phase 2 of the implementation, featuring:
- ✅ Working MCP server with stdio transport
- ✅ Three functional tools (test_connection, find_recipes, get_recipe)
- ✅ PostgreSQL database with pgvector extension
- ✅ Automated Docker container lifecycle management
- ✅ Simplified database schema: recipe_name + full markdown documentation
- ✅ Auto-seeding of initial recipe data
- ✅ Claude Code integration ready

**Database Design:** Simple single-table schema stores recipe name and full markdown documentation. This design is optimized for RAG-based semantic search (Phase 3) where embeddings will be generated from the full markdown text. Enhanced schema designs with structured metadata are documented in `docs/schema-design-research.md` for future consideration.

**Note:** Phase 2 returns all recipes (search intent ignored). Phase 3 will implement semantic search with embeddings.

**Future Phases:**
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

### Updating Recipe Data

To update to the latest OpenRewrite recipes:

```bash
./scripts/rebuild-database.sh
```

This rebuilds the Docker image with fresh data. The image will be tagged with the current date.

To use a specific version, edit `.env`:
```bash
DB_IMAGE_TAG=2025-11-08  # or 'latest'
```

Then restart the server. Run updates periodically (e.g., monthly) to keep recipes current.

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

## Recipe Data

Pre-loaded database image contains **~1000+ recipes** from all official OpenRewrite modules:
- All Spring Boot migrations (2.x → 3.x, etc.)
- Java version upgrades (8 → 11 → 17 → 21)
- Framework migrations (JUnit, Mockito, AssertJ, etc.)
- Security fixes and best practices
- Logging framework migrations
- Dependency updates
- And much more...

**Data Source:** Generated from the official [rewrite-recipe-markdown-generator](https://github.com/openrewrite/rewrite-recipe-markdown-generator) repository, which uses OpenRewrite's RecipeDescriptor API to extract metadata from all published recipe modules.

## Project Structure

```
mcp-server/
├── src/
│   ├── server.py              # Main MCP server
│   ├── config.py              # Configuration management
│   ├── db/
│   │   ├── connection.py      # Database connection pool
│   │   └── queries.py         # Recipe database queries
│   └── tools/
│       ├── test_connection.py # Health check tool
│       ├── find_recipes.py    # Recipe search (database)
│       └── get_recipe.py      # Recipe documentation (database)
├── scripts/
│   ├── startup.sh             # Server startup script (manages Docker lifecycle)
│   ├── setup.sh               # One-time setup (pull/build images, install deps)
│   ├── rebuild-database.sh    # Rebuild pre-loaded database image
│   └── seed_db.py             # Database seeding script (for testing)
├── db-init/
│   ├── 01-create-extensions.sql  # pgvector extension
│   └── 02-create-schema.sql      # Database schema (simplified)
├── docs/
│   └── schema-design-research.md # Enhanced schema research & future designs
├── docker-compose.yml         # PostgreSQL configuration
├── requirements.txt           # Python dependencies
├── .env.example               # Environment template with image configuration
├── .mcp.json                  # Claude Code configuration
└── README.md                  # This file
```

## Database Schema

**Current (Phase 2): Simplified Design**

```sql
CREATE TABLE recipes (
    id SERIAL PRIMARY KEY,
    recipe_name VARCHAR(500) UNIQUE NOT NULL,
    markdown_doc TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE recipe_embeddings (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    embedding vector(384),
    embedding_model VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Design Rationale:**
- Single table stores recipe name and full markdown documentation
- Optimized for RAG: embeddings generated from complete markdown
- Simple to maintain and query
- Future enhancements documented in `docs/schema-design-research.md`

**Future Enhancement Options:**
See `docs/schema-design-research.md` for:
- Structured metadata extraction (options, examples, tags)
- Recipe relationships and composition tracking
- Artifact and source tracking
- Programmatic extraction using OpenRewrite Environment API
```

## Troubleshooting

### Docker Issues
- **Docker not found**: Install Docker Desktop or Docker Engine
- **Port 5432 already in use**: Stop existing PostgreSQL or change `DB_PORT` in .env
- **Permission denied**: Ensure Docker daemon is running and user has permissions
- **Container won't start**: Check logs with `docker-compose logs postgres`
- **Manual cleanup**: Run `docker-compose down -v` to stop and remove containers

### Server not connecting
- Check that Docker is running: `docker ps`
- Check PostgreSQL container is healthy: `docker-compose ps`
- Verify Python dependencies are installed: `pip list | grep asyncpg`
- Check Claude Code logs: `~/Library/Logs/Claude/mcp-server-openrewrite-mcp.log`
- Ensure the startup script is executable: `chmod +x scripts/startup.sh`

### Database connection errors
- Verify container is running: `docker-compose ps`
- Check database logs: `docker-compose logs postgres`
- Test connection: `docker-compose exec postgres psql -U mcp_user -d openrewrite_recipes`
- Verify .env settings match docker-compose.yml

### Tools not appearing
- Restart Claude Code after configuration changes
- Run `/mcp` command to verify server is loaded
- Check stderr logs for any server errors
- Verify database has recipes: `docker-compose exec postgres psql -U mcp_user -d openrewrite_recipes -c "SELECT COUNT(*) FROM recipes;"`

## Logging

- All logs are written to **stderr only** (never stdout, which would corrupt JSON-RPC)
- Logs include timestamps, log levels, and detailed error information
- Check Claude Code's MCP logs for server output

## Next Steps (Future Phases)

**Phase 3**: Semantic Search with Embeddings
- Generate embeddings for all recipes using sentence-transformers
- Implement vector similarity search using pgvector
- Replace simple "return all recipes" logic with true RAG-based search
- Add relevance scoring based on cosine similarity

**Phase 4**: Data Distribution
- Scrape/ingest real OpenRewrite recipe documentation
- Build automated data ingestion pipeline from docs.openrewrite.org
- Create Docker image with pre-loaded recipe database
- Implement version management for recipe updates
- Set up CI/CD for weekly recipe data refreshes

## Contributing

This is part of the rewrite-claude-assisted project. See the main project documentation for contribution guidelines.

## License

[Add license information]

## Support

For issues or questions, please refer to the main project documentation or create an issue in the project repository.
