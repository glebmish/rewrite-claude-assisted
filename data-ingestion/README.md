# OpenRewrite Recipe Data Ingestion Pipeline

A comprehensive data ingestion system that generates OpenRewrite recipe documentation and loads it into a PostgreSQL database for the MCP server.

## Overview

This pipeline uses the official `rewrite-recipe-markdown-generator` repository as the source of truth to:
1. Generate complete markdown documentation for all OpenRewrite recipes
2. Extract structured metadata from the generated markdown
3. Ingest the data into PostgreSQL with recipe_name + full markdown
4. Create a Docker image with pre-loaded recipe data

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Data Ingestion Pipeline                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Setup Generator                                              │
│     ├─ Clone rewrite-recipe-markdown-generator                  │
│     └─ Verify Java 17 environment                               │
│                                                                  │
│  2. Generate Documentation                                       │
│     ├─ Run gradle task to download recipe JARs                  │
│     ├─ Scan JARs using OpenRewrite Environment API              │
│     └─ Generate markdown files (build/docs/recipes/...)         │
│                                                                  │
│  3. Ingest to Database                                           │
│     ├─ Start PostgreSQL container                               │
│     ├─ Apply schema (recipes table)                             │
│     ├─ Walk markdown file tree                                  │
│     ├─ Extract recipe_name from file path/frontmatter           │
│     └─ Insert recipe_name + markdown_doc into database          │
│                                                                  │
│  4. Create Docker Image                                          │
│     ├─ Commit container to new image                            │
│     ├─ Tag with version/date                                    │
│     └─ Push to registry (optional)                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Docker & Docker Compose**: Container management
- **Java 17**: Required by rewrite-recipe-markdown-generator
- **Python 3.8+**: For ingestion scripts
- **Git**: To clone generator repository
- **Disk Space**: ~2GB for generator artifacts + generated docs

## Directory Structure

```
data-ingestion/
├── README.md                    # This file
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment template
├── docker-compose.yml           # PostgreSQL service
├── scripts/
│   ├── 01-setup-generator.sh    # Clone/verify generator repo
│   ├── 02-generate-docs.sh      # Run gradle to generate markdown
│   ├── 03-ingest-docs.py        # Parse markdown and insert to DB
│   ├── 04-create-image.sh       # Commit container to image
│   └── run-full-pipeline.sh     # Orchestrate entire process
└── workspace/
    └── rewrite-recipe-markdown-generator/  # Cloned generator (created by script)
```

## Quick Start

### 1. Setup Environment

```bash
cd data-ingestion
cp .env.example .env
# Edit .env if needed (defaults work out of the box)
```

### 2. Run Full Pipeline

```bash
./scripts/run-full-pipeline.sh
```

This will:
- Clone the generator repository (if not exists)
- Generate all recipe documentation (~10-15 minutes)
- Start PostgreSQL and ingest data (~5 minutes)
- Create a Docker image with the data

### 3. Use the Generated Image

The pipeline creates a Docker image named `openrewrite-recipes-db:latest` that contains all recipe data pre-loaded.

To use it with the MCP server:
```bash
cd ../mcp-server
# Update docker-compose.yml to use the new image
docker-compose up -d
```

## Individual Pipeline Stages

### Stage 1: Setup Generator

```bash
./scripts/01-setup-generator.sh
```

**What it does:**
- Clones `rewrite-recipe-markdown-generator` to `workspace/`
- Verifies Java 17 is available
- Sets up Gradle wrapper

**Output:**
- `workspace/rewrite-recipe-markdown-generator/` directory

### Stage 2: Generate Documentation

```bash
./scripts/02-generate-docs.sh
```

**What it does:**
- Runs `./gradlew run` in the generator repository
- Downloads all OpenRewrite recipe JARs (~1GB)
- Scans JARs using RecipeDescriptor API
- Generates markdown documentation for ~1000+ recipes
- Outputs to `workspace/rewrite-recipe-markdown-generator/build/docs/`

**Output:**
- `build/docs/recipes/` - Organized markdown files by package
- Each recipe has a `.md` file with full documentation

**Note:** This step takes 10-15 minutes on first run (downloads JARs). Subsequent runs are faster.

### Stage 3: Ingest to Database

```bash
./scripts/03-ingest-docs.py
```

**What it does:**
- Starts PostgreSQL container if not running
- Applies schema from `../mcp-server/db-init/`
- Walks the `build/docs/recipes/` directory tree
- For each markdown file:
  - Extracts fully qualified recipe name
  - Reads full markdown content
  - Inserts into `recipes` table (recipe_name, markdown_doc)
- Reports progress and statistics

**Output:**
- PostgreSQL database populated with recipes
- Summary: `Ingested X recipes successfully`

**Recipe Name Extraction:**

The script determines the fully qualified recipe name using:
1. **Frontmatter YAML** (if present):
   ```yaml
   ---
   sidebar_label: "Recipe Name"
   recipe_id: "org.openrewrite.java.ChangeType"
   ---
   ```
2. **Bold text pattern** in markdown:
   ```markdown
   **org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0**
   ```
3. **File path convention**: `build/docs/recipes/java/changetype.md`
   - Maps to package structure
   - Converts to: `org.openrewrite.java.ChangeType`

### Stage 4: Create Docker Image

```bash
./scripts/04-create-image.sh
```

**What it does:**
- Commits the PostgreSQL container to a new image
- Tags with date and version
- Optionally pushes to Docker registry
- Preserves all recipe data in the image

**Output:**
- Docker image: `openrewrite-recipes-db:YYYY-MM-DD`
- Docker image: `openrewrite-recipes-db:latest`

**Usage:**
```bash
# Use the image directly
docker run -p 5432:5432 openrewrite-recipes-db:latest

# Or update mcp-server docker-compose.yml
services:
  postgres:
    image: openrewrite-recipes-db:latest
    # ... rest of config
```

## Configuration

### Environment Variables (.env)

```bash
# Generator settings
GENERATOR_REPO_URL=https://github.com/openrewrite/rewrite-recipe-markdown-generator.git
GENERATOR_WORKSPACE=./workspace
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Database settings (should match mcp-server)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=openrewrite_recipes
DB_USER=mcp_user
DB_PASSWORD=changeme
POSTGRES_CONTAINER=openrewrite-postgres

# Docker image settings
IMAGE_NAME=openrewrite-recipes-db
IMAGE_TAG=latest
REGISTRY_URL=  # Optional: docker.io/yourusername
```

## Advanced Usage

### Incremental Updates

To update the database with new recipe versions:

```bash
# Generate fresh documentation
./scripts/02-generate-docs.sh

# Re-ingest (uses UPSERT to update existing recipes)
./scripts/03-ingest-docs.py
```

The ingestion script uses `ON CONFLICT (recipe_name) DO UPDATE` to handle updates gracefully.

### Custom Generator Options

Edit `scripts/02-generate-docs.sh` to pass custom arguments:

```bash
# Generate only latest versions (faster)
./gradlew run -PlatestVersionsOnly=true

# Generate to custom directory
./gradlew run --args="/custom/output/path"
```

### Database Schema Migration

The ingestion script automatically applies schema from:
- `../mcp-server/db-init/01-create-extensions.sql` (pgvector)
- `../mcp-server/db-init/02-create-schema.sql` (recipes table)

To modify the schema:
1. Edit the schema files in `mcp-server/db-init/`
2. Re-run ingestion: `./scripts/03-ingest-docs.py`

### Testing Without Full Pipeline

Test individual stages:

```bash
# Test database connection
docker-compose up -d
python3 -c "import asyncpg; import asyncio; asyncio.run(asyncpg.connect('postgresql://mcp_user:changeme@localhost/openrewrite_recipes'))"

# Test markdown parsing
./scripts/03-ingest-docs.py --dry-run  # (requires implementation)

# Test image creation without data
./scripts/04-create-image.sh --test
```

## Troubleshooting

### Java Version Issues

**Error:** `UnsupportedClassVersionError`

**Solution:**
```bash
# Check Java version
java -version  # Should be 17+

# Set JAVA_HOME in .env
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### Gradle Build Failures

**Error:** Gradle build fails with dependency errors

**Solution:**
```bash
cd workspace/rewrite-recipe-markdown-generator
./gradlew clean
./gradlew run  # Retry
```

### Database Connection Failures

**Error:** `asyncpg.exceptions.CannotConnectNowError`

**Solution:**
```bash
# Check if PostgreSQL is running
docker-compose ps

# Check logs
docker-compose logs postgres

# Restart container
docker-compose restart postgres
```

### Disk Space Issues

**Error:** No space left on device

**Solution:**
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Clean gradle cache
cd workspace/rewrite-recipe-markdown-generator
./gradlew clean
rm -rf ~/.gradle/caches/*
```

### Missing Markdown Files

**Error:** No recipes found in build/docs/recipes/

**Solution:**
```bash
# Verify generation completed
cd workspace/rewrite-recipe-markdown-generator
ls -R build/docs/recipes/ | head -20

# Re-run generation
./gradlew clean run
```

## Data Statistics

After running the full pipeline, you can expect:

- **Total Recipes**: ~1000-1500 recipes
- **Total Markdown Size**: ~50-100 MB
- **Database Size**: ~150-200 MB
- **Docker Image Size**: ~500 MB (includes PostgreSQL + data)
- **Generation Time**: 10-15 minutes (first run)
- **Ingestion Time**: 3-5 minutes

## Maintenance

### Weekly Update Schedule

Recommended automation for keeping recipe data current:

```bash
# Add to crontab
0 2 * * 1 cd /path/to/data-ingestion && ./scripts/run-full-pipeline.sh
```

This runs every Monday at 2 AM to:
1. Pull latest generator code
2. Regenerate documentation with latest recipes
3. Update database
4. Create new versioned image

### Version Tagging

Tag images with dates for rollback capability:

```bash
# After successful pipeline run
docker tag openrewrite-recipes-db:latest openrewrite-recipes-db:2025-11-08
docker push openrewrite-recipes-db:2025-11-08
```

### Monitoring

Check ingestion health:

```bash
# Recipe count
docker-compose exec postgres psql -U mcp_user -d openrewrite_recipes -c "SELECT COUNT(*) FROM recipes;"

# Recent updates
docker-compose exec postgres psql -U mcp_user -d openrewrite_recipes -c "SELECT recipe_name, updated_at FROM recipes ORDER BY updated_at DESC LIMIT 10;"

# Database size
docker-compose exec postgres psql -U mcp_user -d openrewrite_recipes -c "SELECT pg_size_pretty(pg_database_size('openrewrite_recipes'));"
```

## Integration with MCP Server

The MCP server automatically uses the database populated by this pipeline:

1. **Development**: Use docker-compose in mcp-server/ (ephemeral data)
2. **Production**: Use the Docker image created by this pipeline (persistent data)

Update `mcp-server/docker-compose.yml`:

```yaml
services:
  postgres:
    image: openrewrite-recipes-db:latest  # Use pre-loaded image
    # Remove db-init volume mounts (schema already applied)
    environment:
      POSTGRES_DB: openrewrite_recipes
      POSTGRES_USER: mcp_user
      POSTGRES_PASSWORD: changeme
```

## Future Enhancements

Documented in `mcp-server/docs/schema-design-research.md`:

- Phase 3: Add embeddings generation for semantic search
- Phase 4: Extract structured metadata (options, examples, tags)
- Phase 5: Recipe relationship tracking
- Phase 6: Automated testing and validation

## License

Part of the rewrite-claude-assisted project. See main project for license information.

## Support

For issues or questions:
- Check the main project documentation
- Review `mcp-server/docs/schema-design-research.md` for schema details
- See OpenRewrite documentation: https://docs.openrewrite.org
