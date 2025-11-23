# OpenRewrite Recipe Data Ingestion Pipeline

A comprehensive data ingestion system that generates OpenRewrite recipe documentation, extracts structured metadata, creates semantic embeddings, and loads everything into a PostgreSQL database for the MCP server.

## Overview

This pipeline uses the official `rewrite-recipe-markdown-generator` repository as the source of truth to:
1.  Generate complete markdown documentation for all OpenRewrite recipes.
2.  Extract structured metadata (name, description, options, tags) from the recipes.
3.  Ingest the markdown documentation and structured metadata into PostgreSQL.
4.  Generate semantic vector embeddings for each recipe to enable powerful semantic search capabilities.
5.  Create a self-contained Docker image with all data pre-loaded.

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
│     └─ Generate markdown files (build/docs/recipes/...)         │
│                                                                  |
│  2b. Generate Structured Data                                    │
│     ├─ Run custom gradle task to scan JARs                      │
│     └─ Extract metadata (name, desc, options) to JSON file      │
│                                                                  │
│  3. Ingest to Database                                           │
│     ├─ Start PostgreSQL container                               │
│     ├─ Apply schema (recipes, recipe_metadata tables)           │
│     ├─ Walk markdown file tree and insert into 'recipes' table  │
│     └─ Insert structured data into 'recipe_metadata' table     │
│                                                                  │
│  3b. Generate Embeddings                                         │
│     ├─ Read structured metadata from database                   │
│     ├─ Generate vector embeddings using SentenceTransformer     │
│     └─ Insert embeddings into 'recipe_embeddings' table        │
│                                                                  │
│  4. Create Docker Image                                          │
│     ├─ Dump database to SQL file                                │
│     ├─ Build new image with data loading on startup             │
│     └─ Tag with version/date                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

-   **Docker & Docker Compose**: Container management
-   **Java 17**: Required by rewrite-recipe-markdown-generator
-   **Python 3.8+**: For ingestion scripts
-   **Git**: To clone generator repository
-   **Disk Space**: ~3GB for generator artifacts, generated docs, and embedding models.

## Directory Structure

```
data-ingestion/
├── README.md                    # This file
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment template
├── docker-compose.yml           # PostgreSQL service
├── scripts/
│   ├── 00-init-database.sh      # Initializes the database container and schema
│   ├── 01-setup-generator.sh    # Clones/verifies the generator repo
│   ├── 02-generate-docs.sh      # Runs gradle to generate markdown
│   ├── 02b-generate-structured-data.sh # Extracts structured metadata to JSON
│   ├── 03-ingest-docs.py        # Parses markdown and inserts into DB
│   ├── 03b-generate-embeddings.py # Generates and inserts vector embeddings
│   ├── 04-create-image.sh       # Commits container to a new Docker image
│   └── run-full-pipeline.sh     # Orchestrates the entire process
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

This will execute all stages in order:
-   Initialize the database.
-   Clone the generator repository (if it doesn't exist).
-   Generate all recipe documentation (~10-15 minutes).
-   Extract structured metadata into a JSON file.
-   Start PostgreSQL and ingest documentation and metadata.
-   Generate and ingest vector embeddings for all recipes.
-   Create a final Docker image with all data included.

### 3. Use the Generated Image

The pipeline creates a Docker image named `openrewrite-recipes-db:latest` that contains all recipe data pre-loaded.

To use it with the MCP server:
```bash
cd ../mcp-server
# Update docker-compose.yml to use the new image
docker-compose up -d
```

## Individual Pipeline Stages

### Stage 0: Initialize Database
```bash
./scripts/00-init-database.sh [--reset]
```
- Starts the PostgreSQL container.
- Applies the full schema, including `pgvector` extension and tables for recipes, metadata, and embeddings.
- Use `--reset` to force-remove an existing container for a clean start.

### Stage 1: Setup Generator
```bash
./scripts/01-setup-generator.sh
```
- Clones `rewrite-recipe-markdown-generator` to `workspace/`.
- Verifies Java 17 is available.

### Stage 2: Generate Documentation
```bash
./scripts/02-generate-docs.sh
```
- Runs `./gradlew run` in the generator repository to produce markdown documentation for all recipes.
- Outputs to `workspace/rewrite-recipe-markdown-generator/build/docs/`.

### Stage 2b: Generate Structured Data
```bash
./scripts/02b-generate-structured-data.sh
```
- Runs a custom Gradle task (`extractRecipeMetadata`) that scans recipe JARs.
- Extracts detailed metadata (name, description, parameters, tags) for each recipe.
- Outputs a `recipe-metadata.json` file.

### Stage 3: Ingest Documentation & Metadata
```bash
./scripts/03-ingest-docs.py
```
- Reads markdown files and ingests their content into the `recipes` table.
- Reads the `recipe-metadata.json` file and ingests its content into the `recipe_metadata` table.

### Stage 3b: Generate Embeddings
```bash
./scripts/03b-generate-embeddings.py
```
- Loads a sentence-transformer model (e.g., `all-MiniLM-L6-v2`).
- For each recipe, creates a structured text document from its metadata.
- Generates a vector embedding from the text.
- Inserts the vector into the `recipe_embeddings` table.

### Stage 4: Create Docker Image
```bash
./scripts/04-create-image.sh
```
- Exports the entire database using `pg_dump`.
- Builds a new Docker image from a Dockerfile, configured to load the data dump on its first startup.
- This method correctly captures all data, including that in PostgreSQL volumes.
- Tags the image with a version and date.

## Database Schema

The schema is defined in `db-init/*.sql` and includes:
-   `recipes`: Stores the raw markdown documentation for each recipe.
-   `recipe_metadata`: Stores structured data like display name, description, and tags.
-   `recipe_embeddings`: Stores vector embeddings for semantic search, linked to each recipe. It includes an HNSW index for efficient similarity searches.

## Configuration

### Environment Variables (.env)

```bash
# Generator settings
GENERATOR_REPO_URL=https://github.com/openrewrite/rewrite-recipe-markdown-generator.git
GENERATOR_WORKSPACE=./workspace
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=openrewrite_recipes
DB_USER=mcp_user
DB_PASSWORD=changeme
POSTGRES_CONTAINER_NAME=openrewrite-postgres

# Embedding settings
EMBEDDING_MODEL=all-MiniLM-L6-v2
EMBEDDING_DIMENSION=384

# Docker image settings
IMAGE_NAME=openrewrite-recipes-db
IMAGE_TAG=latest
REGISTRY_URL=  # Optional: docker.io/yourusername
```

## Future Enhancements

-   Recipe relationship tracking (e.g., parent/child recipes).
-   Automated testing and validation of ingested data.
-   Integration with more powerful, production-grade embedding models.
