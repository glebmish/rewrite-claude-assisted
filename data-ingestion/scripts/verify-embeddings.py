#!/usr/bin/env python3
"""
Quick script to verify embeddings using the same connection parameters as 03b-generate-embeddings.py
This ensures we're checking the exact same database the embedding script is using.
"""

import asyncio
import asyncpg
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Configuration (same as 03b-generate-embeddings.py)
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent

# Load environment variables
load_dotenv(PROJECT_DIR / '.env')

# Database configuration
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', '5432'))
DB_NAME = os.getenv('DB_NAME', 'openrewrite_recipes')
DB_USER = os.getenv('DB_USER', 'mcp_user')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'changeme')
EMBEDDING_MODEL = os.getenv('EMBEDDING_MODEL', 'all-MiniLM-L6-v2')


async def verify_embeddings():
    """Verify embeddings in the database."""

    print("=" * 60)
    print("Embedding Verification (using same connection as 03b script)")
    print("=" * 60)
    print()

    print(f"Connection details:")
    print(f"  Host: {DB_HOST}")
    print(f"  Port: {DB_PORT}")
    print(f"  Database: {DB_NAME}")
    print(f"  User: {DB_USER}")
    print()

    try:
        # Connect using same parameters as 03b script
        print("→ Connecting to database...")
        conn = await asyncpg.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        print("✓ Connected")
        print()

        # Query 1: Total count
        print("1. Total embeddings:")
        total = await conn.fetchval("SELECT COUNT(*) FROM recipe_embeddings")
        print(f"   {total} total embeddings")
        print()

        # Query 2: Count by model
        print("2. Embeddings by model:")
        rows = await conn.fetch(
            "SELECT embedding_model, COUNT(*) as count FROM recipe_embeddings GROUP BY embedding_model"
        )
        if rows:
            for row in rows:
                print(f"   {row['embedding_model']}: {row['count']}")
        else:
            print("   No embeddings found")
        print()

        # Query 3: Check for NULL embeddings
        print("3. NULL check:")
        result = await conn.fetchrow(
            """SELECT
                COUNT(*) as total,
                COUNT(embedding) as with_embedding,
                COUNT(*) - COUNT(embedding) as null_embeddings
            FROM recipe_embeddings"""
        )
        print(f"   Total rows: {result['total']}")
        print(f"   With embedding: {result['with_embedding']}")
        print(f"   NULL embeddings: {result['null_embeddings']}")
        print()

        # Query 4: Sample embeddings with details
        print("4. Sample embeddings (first 3):")
        rows = await conn.fetch("""
            SELECT
                re.id,
                re.recipe_id,
                r.recipe_name,
                re.embedding_model,
                substring(re.embedding::text, 1, 60) || '...' as embedding_preview,
                re.created_at
            FROM recipe_embeddings re
            JOIN recipes r ON r.id = re.recipe_id
            LIMIT 3
        """)

        if rows:
            for row in rows:
                print(f"   ID: {row['id']}")
                print(f"   Recipe: {row['recipe_name']}")
                print(f"   Model: {row['embedding_model']}")
                print(f"   Embedding: {row['embedding_preview']}")
                print(f"   Created: {row['created_at']}")
                print()
        else:
            print("   No embeddings found")

        # Query 5: Specific model check (same as 03b verification)
        print(f"5. Embeddings for model '{EMBEDDING_MODEL}':")
        count = await conn.fetchval(
            "SELECT COUNT(*) FROM recipe_embeddings WHERE embedding_model = $1",
            EMBEDDING_MODEL
        )
        print(f"   {count} embeddings")
        print()

        await conn.close()

        print("=" * 60)
        if total == 0:
            print("❌ NO EMBEDDINGS FOUND!")
            print("   The table exists but contains no data.")
        elif total > 0:
            print(f"✓ Found {total} embeddings in the database")
        print("=" * 60)

    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    asyncio.run(verify_embeddings())
