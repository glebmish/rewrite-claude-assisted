#!/usr/bin/env python3
"""Seed database with initial recipe data from Phase 1 mock data."""
import asyncio
import asyncpg
import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

# Import existing mock data
from tools.find_recipes import MOCK_RECIPES
from tools.get_recipe import MOCK_RECIPE_DOCS


async def seed_database(
    host: str = "localhost",
    port: int = 5432,
    database: str = "openrewrite_recipes",
    user: str = "mcp_user",
    password: str = "changeme"
):
    """Populate database with mock data."""
    print(f"Connecting to database {database} at {host}:{port}...")

    try:
        conn = await asyncpg.connect(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password,
            timeout=10
        )
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}", file=sys.stderr)
        print(f"   Make sure PostgreSQL is running: docker-compose up -d", file=sys.stderr)
        sys.exit(1)

    try:
        print(f"Seeding {len(MOCK_RECIPES)} recipes...")

        for recipe_data in MOCK_RECIPES:
            recipe_id = recipe_data['recipe_id']
            print(f"  - {recipe_data['name']}")

            # Insert recipe
            recipe_row_id = await conn.fetchval("""
                INSERT INTO recipes (recipe_id, name, description, tags)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (recipe_id) DO UPDATE
                SET name = EXCLUDED.name,
                    description = EXCLUDED.description,
                    tags = EXCLUDED.tags,
                    updated_at = NOW()
                RETURNING id
            """, recipe_id, recipe_data['name'],
                recipe_data['description'], recipe_data['tags'])

            # Insert full details if available
            if recipe_id in MOCK_RECIPE_DOCS:
                full_doc = MOCK_RECIPE_DOCS[recipe_id]

                await conn.execute("""
                    UPDATE recipes
                    SET full_documentation = $1,
                        usage_instructions = $2,
                        source_url = $3,
                        updated_at = NOW()
                    WHERE id = $4
                """, full_doc.get('full_documentation'),
                    full_doc.get('usage_instructions'),
                    full_doc.get('source_url'),
                    recipe_row_id)

                # Delete existing examples and options for this recipe (for idempotency)
                await conn.execute(
                    "DELETE FROM recipe_examples WHERE recipe_id = $1",
                    recipe_row_id
                )
                await conn.execute(
                    "DELETE FROM recipe_options WHERE recipe_id = $1",
                    recipe_row_id
                )

                # Insert examples
                for idx, example in enumerate(full_doc.get('examples', [])):
                    await conn.execute("""
                        INSERT INTO recipe_examples
                        (recipe_id, title, before_code, after_code, display_order)
                        VALUES ($1, $2, $3, $4, $5)
                    """, recipe_row_id, example['title'],
                        example['before'], example['after'], idx)

                # Insert options
                for idx, option in enumerate(full_doc.get('options', [])):
                    await conn.execute("""
                        INSERT INTO recipe_options
                        (recipe_id, name, type, description, default_value, display_order)
                        VALUES ($1, $2, $3, $4, $5, $6)
                    """, recipe_row_id, option['name'], option['type'],
                        option['description'], str(option['default']), idx)

        count = await conn.fetchval("SELECT COUNT(*) FROM recipes")
        print(f"\n✅ Database seeded successfully with {count} recipes")

    except Exception as e:
        print(f"❌ Error seeding database: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        await conn.close()


if __name__ == "__main__":
    # Read from environment or use defaults
    host = os.getenv("DB_HOST", "localhost")
    port = int(os.getenv("DB_PORT", "5432"))
    database = os.getenv("DB_NAME", "openrewrite_recipes")
    user = os.getenv("DB_USER", "mcp_user")
    password = os.getenv("DB_PASSWORD", "changeme")

    asyncio.run(seed_database(host, port, database, user, password))
