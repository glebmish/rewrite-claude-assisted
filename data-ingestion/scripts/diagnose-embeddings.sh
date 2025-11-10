#!/usr/bin/env bash
set -euo pipefail

# Script to diagnose embedding storage issues
# Run this to check if embeddings are actually in the database

echo "========================================="
echo "Embedding Diagnostics"
echo "========================================="
echo ""

# Check running postgres containers
echo "→ Checking running PostgreSQL containers:"
docker ps | grep -i postgres || echo "  No postgres containers found"
echo ""

# Check database connection from 03b script's perspective
echo "→ Connection details from .env:"
if [ -f "../.env" ]; then
    grep -E "^DB_" ../.env || echo "  No DB_ variables found in .env"
else
    echo "  .env file not found"
fi
echo ""

# Query the database
CONTAINER_NAME="openrewrite-postgres"
DB_USER="mcp_user"
DB_NAME="openrewrite_recipes"

echo "→ Querying recipe_embeddings table (using container: $CONTAINER_NAME):"
echo ""

# Check total count
echo "1. Total embeddings count:"
docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) as total_embeddings FROM recipe_embeddings;" || echo "  Query failed"
echo ""

# Check by model
echo "2. Embeddings by model:"
docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT embedding_model, COUNT(*) as count FROM recipe_embeddings GROUP BY embedding_model;" || echo "  Query failed"
echo ""

# Show sample rows
echo "3. Sample embeddings (first 3):"
docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, recipe_id, embedding_model, created_at, substring(embedding::text, 1, 50) || '...' as embedding_preview FROM recipe_embeddings LIMIT 3;" || echo "  Query failed"
echo ""

# Check if embeddings column has data
echo "4. Check embedding column nulls:"
docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) as total, COUNT(embedding) as with_embedding, COUNT(*) - COUNT(embedding) as null_embeddings FROM recipe_embeddings;" || echo "  Query failed"
echo ""

# Check recipe_metadata for comparison
echo "5. Recipe metadata count (should match processed count):"
docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) as metadata_count FROM recipe_metadata;" || echo "  Query failed"
echo ""

echo "========================================="
echo "If you see '0 rows' or no data above, but the script says 23 embeddings exist,"
echo "then the script might be connecting to a different database or container."
echo "========================================="
